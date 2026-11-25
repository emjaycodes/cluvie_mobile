import 'dart:io';

import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Review round 3 B1/B2 regressions, measured with the real bundled fonts
/// (the default test font is wider and gives false results).
Future<void> _loadFonts() async {
  for (final (fam, files) in [
    ('Sora', ['SemiBold', 'Bold', 'ExtraBold']),
    ('PlusJakartaSans', ['Regular', 'Medium', 'SemiBold', 'Bold']),
  ]) {
    final loader = FontLoader(fam);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$fam-$f.ttf').readAsBytesSync())));
    }
    await loader.load();
  }
}

final _heading = find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().startsWith('Join the club.'),
);

const _sizes = [Size(320, 568), Size(375, 667), Size(390, 844)];
const _scales = [1.0, 1.3];

Future<void> _pump(WidgetTester t, Widget screen, Size size, double scale) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: AppTheme.theme,
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: screen,
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await _loadFonts();
  });

  for (final size in _sizes) {
    for (final scale in _scales) {
      final label = '${size.width.toInt()}x${size.height.toInt()} @${scale}x';

      testWidgets('onboarding pages never overflow ($label)', (t) async {
        await _pump(t, const OnboardingScreen(), size, scale);
        for (var page = 0; page < 3; page++) {
          expect(t.takeException(), isNull, reason: 'page ${page + 1} overflowed at $label');
          if (page < 2) {
            await t.tap(find.byType(ClButton));
            await t.pumpAndSettle();
          }
        }
      });

      testWidgets('welcome heading sits on the solid panel, not the poster wall ($label)', (t) async {
        await _pump(t, const WelcomeScreen(), size, scale);
        expect(t.takeException(), isNull);
        final headingTop = t.getTopLeft(_heading).dy;
        // Copy must start on the solid 96% panel, never on the fade above it.
        final opaqueFrom = t.getTopLeft(find.byKey(const ValueKey('welcome-panel'))).dy;
        expect(headingTop, greaterThanOrEqualTo(opaqueFrom), reason: 'heading starts on the fade at $label');
      });
    }
  }
}
