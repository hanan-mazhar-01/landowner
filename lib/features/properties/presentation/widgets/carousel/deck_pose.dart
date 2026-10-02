import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';

/// Where one card sits in the deck, derived purely from its distance to the
/// current page (`d = index - page`). Continuous in `d`, so the deck follows
/// the finger frame by frame instead of animating after the swipe.
@immutable
class DeckPose {
  const DeckPose({
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.scale,
    required this.opacity,
    required this.depth,
  });

  /// Offsets in logical pixels, rotation in radians.
  final double dx, dy, rotation, scale, opacity;

  /// 0 = at rest in front … 1+ = further back. Drives paint order and shadow.
  final double depth;

  bool get visible => opacity > 0.01;
}

/// Deck geometry, adapted from the reference: next cards fan out behind the
/// active card (to the right, tilting clockwise); the previous card rests as
/// a faded, tilted sliver on the left.
class DeckLayout {
  const DeckLayout({required this.viewportWidth, required this.cardWidth, required this.cardHeight, this.reduceMotion = false});

  final double viewportWidth, cardWidth, cardHeight;
  final bool reduceMotion;

  static const _deg = math.pi / 180;

  /// Resting slots behind the active card: 1, 2, 3 (3 fades out).
  static const _stackDx = [0.0, 0.050, 0.085, 0.105]; // × viewport width
  static const _stackDy = [0.0, -0.030, -0.052, -0.066]; // × card height
  static const _stackRot = [0.0, 5.0, 9.0, 11.0]; // degrees
  static const _stackScale = [1.0, 0.93, 0.87, 0.82];
  static const _stackOpacity = [1.0, 0.72, 0.42, 0.0];

  /// Previous card at rest (d = -1) and fully gone (d = -2).
  static const _prevRot = -6.0, _prevScale = 0.88, _prevOpacity = 0.55, _prevDrop = 0.02;

  /// Horizontal distance of one page for the finger (the PageView page width).
  double get pageExtent => cardWidth;

  /// Resting x of the previous card: tucked behind, a sliver visible at left.
  double get _prevX => -(viewportWidth / 2 + cardWidth * 0.5 * _prevScale - viewportWidth * 0.13);

  DeckPose pose(double d) {
    if (d >= 0) return _behind(d);
    return _leaving(-d);
  }

  /// d ∈ [0, 3+]: active → stacked behind.
  DeckPose _behind(double d) {
    final i = d.floor().clamp(0, 2), t = (d - i).clamp(0.0, 1.0);
    final j = i + 1;
    double l(List<double> v) => lerpDouble(v[i], v[j], d >= 3 ? 1 : t)!;
    final opacity = d >= 3 ? 0.0 : l(_stackOpacity);
    return DeckPose(
      dx: l(_stackDx) * viewportWidth,
      dy: l(_stackDy) * cardHeight,
      rotation: reduceMotion ? 0 : l(_stackRot) * _deg,
      scale: reduceMotion ? 1 : l(_stackScale),
      opacity: opacity,
      depth: d,
    );
  }

  /// a = |d| ∈ (0, 2]: active → previous (left sliver) → gone.
  DeckPose _leaving(double a) {
    if (a <= 1) {
      // Starts exactly under the finger (slope = pageExtent), eases into the
      // resting sliver position so it never overshoots.
      // f(a) = P·a + (R − P)·a²  →  f(0)=0, f'(0)=P (finger speed), f(1)=R.
      final p = pageExtent, r = -_prevX;
      final follow = p * a + (r - p) * a * a;
      final ease = _easeOut(a);
      return DeckPose(
        dx: -follow,
        dy: _prevDrop * cardHeight * ease,
        rotation: reduceMotion ? 0 : _prevRot * _deg * ease,
        scale: reduceMotion ? 1 : lerpDouble(1, _prevScale, ease)!,
        opacity: lerpDouble(1, _prevOpacity, ease)!,
        // Stays above the incoming card until ~55% so it visibly passes in
        // front before tucking behind, as in the reference.
        depth: a * 1.1,
      );
    }
    final t = (a - 1).clamp(0.0, 1.0);
    return DeckPose(
      dx: _prevX - t * viewportWidth * 0.25,
      dy: _prevDrop * cardHeight,
      rotation: reduceMotion ? 0 : (_prevRot - 3 * t) * _deg,
      scale: reduceMotion ? 1 : _prevScale - 0.04 * t,
      opacity: _prevOpacity * (1 - t),
      depth: 1.1 + t,
    );
  }
}

double _easeOut(double t) => 1 - (1 - t) * (1 - t);
