import 'package:flutter/widgets.dart';

/// The first of [styles] (largest first) at which every word of [text] fits
/// in [maxWidth], so long words ("Assassination") wrap between words instead
/// of breaking mid-word at large text sizes. Falls back to the last style.
TextStyle styleThatFits(
  String text,
  List<TextStyle> styles, {
  required double maxWidth,
  required TextScaler textScaler,
}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  for (final style in styles) {
    var fits = true;
    for (final w in words) {
      final tp = TextPainter(text: TextSpan(text: w, style: style), textScaler: textScaler, textDirection: TextDirection.ltr)
        ..layout();
      final width = tp.width;
      tp.dispose();
      if (width > maxWidth) {
        fits = false;
        break;
      }
    }
    if (fits) return style;
  }
  return styles.last;
}

/// A [Text] whose style steps down through [styles] until its longest word
/// fits the available width.
class FitWordsText extends StatelessWidget {
  const FitWordsText(this.text, {super.key, required this.styles, this.maxLines, this.overflow});

  final String text;
  final List<TextStyle> styles;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final style = styleThatFits(
        text,
        styles,
        maxWidth: constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    });
  }
}
