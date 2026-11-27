import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Sora + Plus Jakarta Sans so layout tests measure real
/// glyph widths (the default test font is wider and gives false overflows).
Future<void> loadRealFonts() async {
  for (final (family, weights) in [
    ('Sora', ['SemiBold', 'Bold', 'ExtraBold']),
    ('PlusJakartaSans', ['Regular', 'Medium', 'SemiBold', 'Bold']),
  ]) {
    final loader = FontLoader(family);
    for (final w in weights) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$family-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  }
}
