import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native share sheet — also the "Save to Files / Download" path on iOS and
/// Android, so nothing is written outside the app sandbox without consent.
abstract final class ShareService {
  /// iPad presents the share sheet as a popover and requires an anchor rect;
  /// without one the share call throws. Anchor to the centre of the screen.
  static Rect get _origin {
    final view = PlatformDispatcher.instance.implicitView ?? PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1);
  }

  static Future<void> file(String path, {String? subject, String? text}) => SharePlus.instance
      .share(ShareParams(files: [XFile(path)], subject: subject, text: text, sharePositionOrigin: _origin));

  static Future<void> text(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: _origin));

  /// Writes bytes to a temp file and shares it.
  static Future<void> bytes(List<int> data, String filename, {String? subject}) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(data, flush: true);
    await file(f.path, subject: subject);
  }
}
