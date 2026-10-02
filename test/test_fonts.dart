import 'dart:io';

import 'package:flutter/services.dart';

/// Loads Manrope (and a stand-in for the system font) so widget tests lay
/// text out like a device instead of with the wide placeholder test font.
Future<void> loadAppFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      if (File(f).existsSync()) loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await family('Manrope', [for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/Manrope-$w.ttf']);
  const lato = '/usr/share/fonts/truetype/lato';
  await family('Roboto', [for (final w in ['Regular', 'Medium', 'Semibold', 'Bold']) '$lato/Lato-$w.ttf']);
}
