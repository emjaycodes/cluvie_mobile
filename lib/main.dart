import 'package:cluvie_mobile/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Sora', 'PlusJakartaSans']) {
      final text = await rootBundle.loadString('assets/fonts/OFL-$font.txt');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
  runApp(ProviderScope(child: const MyApp()));
}

