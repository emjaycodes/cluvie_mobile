import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared design-rule checks for screen tests (tokens.md rules).

bool isGold(Color? c) =>
    c != null && (c.toARGB32() == AppColors.gold.toARGB32() || c.toARGB32() == AppColors.goldDeep.toARGB32());

bool _decorationIsGold(Decoration? d) {
  if (d is! BoxDecoration) return false;
  final g = d.gradient;
  final border = d.border;
  return isGold(d.color) ||
      (g != null && g.colors.any(isGold)) ||
      (border is Border &&
          [border.top, border.bottom, border.left, border.right].any((s) => s.style != BorderStyle.none && isGold(s.color)));
}

/// Every widget painting gold that isn't inside one of [allowed] (the screen's
/// one gold owner), the logo or the floating nav (active tab). The focus ring
/// only shows when focused, so it never appears here.
List<String> goldViolations(WidgetTester t, {List<Finder> allowed = const []}) {
  final ok = <Element>{
    for (final f in allowed) ...f.evaluate(),
    ...find.byType(ClLogo).evaluate(),
    // Only the floating nav itself, not the whole shell: screens are
    // descendants of ClBottomNavBar.
    ...find.byWidgetPredicate((w) => w.runtimeType.toString() == '_FloatingNav').evaluate(),
  };
  bool underAllowed(Element e) {
    var found = ok.contains(e);
    if (!found) {
      e.visitAncestorElements((a) {
        if (ok.contains(a)) found = true;
        return !found;
      });
    }
    return found;
  }

  final out = <String>[];
  for (final e in find.byWidgetPredicate((_) => true).evaluate()) {
    final w = e.widget;
    final gold = switch (w) {
      Icon(:final color) => isGold(color),
      Text(:final style) => isGold(style?.color),
      RichText(:final text) => isGold(text.style?.color),
      DecoratedBox(:final decoration) => _decorationIsGold(decoration),
      Container(:final decoration, :final color) => isGold(color) || _decorationIsGold(decoration),
      ColoredBox(:final color) => isGold(color),
      RefreshIndicator(:final color) => isGold(color),
      SvgPicture(:final colorFilter) => colorFilter != null && colorFilter.toString().contains('ffffd27d'),
      _ => false,
    };
    if (gold && !underAllowed(e)) out.add(w.toStringShort());
  }
  return out;
}

/// Fails when any wrapping paragraph on screen has a word wider than its box,
/// i.e. a word broken mid-word ("Oppen/heimer"): a layout that's too narrow.
void expectNoBrokenWords(WidgetTester t) {
  for (final e in find.byType(RichText).evaluate()) {
    final p = e.renderObject;
    if (p is! RenderParagraph || !p.hasSize || !p.softWrap || p.maxLines == 1) continue;
    final style = p.text.style;
    final plain = p.text.toPlainText();
    for (final word in plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      final tp = TextPainter(text: TextSpan(text: word, style: style), textScaler: p.textScaler, textDirection: TextDirection.ltr)
        ..layout();
      expect(tp.width, lessThanOrEqualTo(p.size.width + 0.5), reason: '"$word" is broken mid-word in "$plain"');
      tp.dispose();
    }
  }
}

/// Fails when any of [labels] is ellipsized.
void expectNotTruncated(WidgetTester t, Iterable<String> labels) {
  for (final label in labels) {
    for (final e in find.text(label).evaluate()) {
      final p = e.findRenderObject();
      if (p is RenderParagraph) expect(p.didExceedMaxLines, isFalse, reason: '"$label" truncated');
    }
  }
}
