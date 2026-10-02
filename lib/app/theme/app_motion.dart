import 'package:flutter/widgets.dart';

/// Motion tokens from the design. All durations collapse to zero when the
/// platform asks for reduced motion (see [Motion.of]).
abstract final class AppMotion {
  /// `cubic-bezier(.2,.8,.2,1)` — the design's standard curve.
  static const standard = Cubic(.2, .8, .2, 1);

  /// `cubic-bezier(.4,0,.2,1)` — line-chart drawing.
  static const draw = Cubic(.4, 0, .2, 1);

  /// `cubic-bezier(.2,.9,.25,1)` — quick-action fly-out.
  static const flyOut = Cubic(.2, .9, .25, 1);

  static const screenIn = Duration(milliseconds: 380);
  static const transition = Duration(milliseconds: 280);
  static const lineDraw = Duration(milliseconds: 1400);
  static const barGrow = Duration(milliseconds: 600);
  static const barResize = Duration(milliseconds: 450);
  static const fadeUp = Duration(milliseconds: 260);
  static const counter = Duration(milliseconds: 900);
  static const navIndicator = Duration(milliseconds: 340);
  static const plusRotate = Duration(milliseconds: 320);
  static const toggle = Duration(milliseconds: 220);
  static const colorShift = Duration(milliseconds: 200);
  static const scrim = Duration(milliseconds: 240);
  static const toastHold = Duration(milliseconds: 1900);
}

/// Accessibility-aware motion helper.
abstract final class Motion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
