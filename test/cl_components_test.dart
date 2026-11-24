import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: AppTheme.theme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

/// The button's background shape (not ClPressable's foreground focus layer).
DecoratedBox _buttonBox(WidgetTester tester) => tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ClButton),
            matching: find.byWidgetPredicate((w) => w is DecoratedBox && w.position == DecorationPosition.background),
          )
          .first,
    );

void main() {
  group('ClButton', () {
    testWidgets('primary uses the gold gradient and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(ClButton(label: 'Vote', onPressed: () => taps++)));
      final deco = _buttonBox(tester).decoration as BoxDecoration;
      expect(deco.gradient, AppColors.goldGradient);
      await tester.tap(find.text('Vote'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('null onPressed renders disabled and ignores taps', (tester) async {
      await tester.pumpWidget(_host(const ClButton(label: 'Vote', onPressed: null)));
      final deco = _buttonBox(tester).decoration as BoxDecoration;
      expect(deco.color, AppColors.surfaceRaised);
      expect(deco.gradient, isNull);
      final text = tester.widget<Text>(find.text('Vote'));
      expect(text.style?.color, AppColors.textMuted);
    });

    testWidgets('loading shows a spinner in the foreground colour and blocks taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(ClButton(label: 'Save', isLoading: true, onPressed: () => taps++)));
      final spinner = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(spinner.color, AppColors.onGold, reason: 'audit P0: no white spinner on gold');
      await tester.tap(find.byType(ClButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('legacy isSecondary maps to the secondary variant', (tester) async {
      // ignore: deprecated_member_use_from_same_package
      final button = ClButton(label: 'Later', onPressed: () {}, isSecondary: true);
      expect(button.resolvedVariant, ClButtonVariant.secondary);
      await tester.pumpWidget(_host(button));
      final deco = _buttonBox(tester).decoration as BoxDecoration;
      expect(deco.color, AppColors.glassFlat);
    });

    testWidgets('inverse variant is white with dark text', (tester) async {
      await tester.pumpWidget(_host(ClButton(label: 'RSVP', variant: ClButtonVariant.inverse, onPressed: () {})));
      final deco = _buttonBox(tester).decoration as BoxDecoration;
      expect(deco.color, AppColors.textPrimary);
      expect(tester.widget<Text>(find.text('RSVP')).style?.color, AppColors.onGold);
    });

    testWidgets('small size keeps a 48dp hit area', (tester) async {
      await tester.pumpWidget(_host(ClButton(label: 'Go', size: ClButtonSize.sm, expand: false, onPressed: () {})));
      expect(tester.getSize(find.byType(ClButton)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('does not throw inside an unbounded Row', (tester) async {
      await tester.pumpWidget(_host(Row(mainAxisSize: MainAxisSize.min, children: [
        ClButton(label: 'A', onPressed: () {}),
      ])));
      expect(tester.takeException(), isNull);
    });
  });

  group('ClBottomNavBar.indexForLocation', () {
    test('maps every shell route to its tab', () {
      expect(ClBottomNavBar.indexForLocation('/home'), 0);
      expect(ClBottomNavBar.indexForLocation('/'), 0);
      expect(ClBottomNavBar.indexForLocation('/discover?q=dune'), 1);
      expect(ClBottomNavBar.indexForLocation('/suggest'), 2);
      expect(ClBottomNavBar.indexForLocation('/communities/abc'), 3);
      expect(ClBottomNavBar.indexForLocation('/allCommunities'), 3);
      expect(ClBottomNavBar.indexForLocation('/profile'), 4);
      expect(ClBottomNavBar.indexForLocation('/users/42'), 4);
    });

    test('routes list stays aligned with the index mapping', () {
      for (var i = 0; i < ClBottomNavBar.routes.length; i++) {
        expect(ClBottomNavBar.indexForLocation(ClBottomNavBar.routes[i]), i);
      }
    });
  });

  group('Reduced motion', () {
    testWidgets('AppMotion zeroes durations and stagger', (tester) async {
      late AppMotion motion;
      await tester.pumpWidget(_host(Builder(builder: (c) {
        motion = AppMotion.of(c);
        return const SizedBox();
      }), reduceMotion: true));
      expect(motion.reduced, isTrue);
      expect(motion.standard, Duration.zero);
      expect(motion.staggerAt(5), Duration.zero);
    });

    testWidgets('stagger is capped when motion is on', (tester) async {
      late AppMotion motion;
      await tester.pumpWidget(_host(Builder(builder: (c) {
        motion = AppMotion.of(c);
        return const SizedBox();
      })));
      expect(motion.staggerAt(100), motion.staggerAt(AppMotion.staggerCap));
    });

    testWidgets('ClEntrance renders its child immediately with no pending timers', (tester) async {
      await tester.pumpWidget(_host(const ClEntrance(index: 6, child: Text('Hello')), reduceMotion: true));
      // A single frame, no settling: the text must already be fully visible.
      expect(find.text('Hello'), findsOneWidget);
      final inEntrance = find.descendant(of: find.byType(ClEntrance), matching: find.byType(Animate));
      expect(inEntrance, findsNothing, reason: 'reduced motion must skip flutter_animate entirely');
    });

    testWidgets('ClEntrance animates in when motion is on', (tester) async {
      await tester.pumpWidget(_host(const ClEntrance(index: 2, child: Text('Hello'))));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
    });
  });

  group('ClEmptyState', () {
    testWidgets('legacy message-only call still works and action is optional', (tester) async {
      await tester.pumpWidget(_host(const ClEmptyState(message: 'Nothing here')));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(ClButton), findsNothing);
    });

    testWidgets('shows a single action when provided', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(ClEmptyState(
        message: 'Suggest a film to start voting.',
        title: 'No active polls',
        actionLabel: 'Suggest a film',
        onAction: () => taps++,
      )));
      await tester.tap(find.text('Suggest a film'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
