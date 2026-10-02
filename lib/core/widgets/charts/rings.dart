import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';

/// Yield ring on the featured property card (56px, 5px stroke).
class YieldRing extends StatelessWidget {
  const YieldRing({super.key, required this.fraction, required this.label, this.size = 56});
  final double fraction;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
          duration: Motion.of(context, AppMotion.barGrow),
          curve: AppMotion.standard,
          builder: (_, f, _) => CustomPaint(
            painter: _RingPainter(f),
            child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontFamily: 'Manrope', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.f);
  final double f;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 24 / 56;
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(c, r, p..color = AppColors.blue100);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * f, false,
        p..color = AppColors.accent..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.f != f;
}

/// Expense donut (128px, radius 54, 14px stroke) with small gaps between
/// segments, as drawn in the design.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.shares, required this.colors, required this.center, this.size = 128});
  final List<double> shares;
  final List<Color> colors;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.of(context, AppMotion.barGrow),
          curve: AppMotion.standard,
          builder: (_, t, child) => CustomPaint(painter: _DonutPainter(shares, colors, t), child: child),
          child: Center(child: center),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.shares, this.colors, this.t);
  final List<double> shares;
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 54 / 128;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    const gap = 3 / 54; // ~3 units of arc between segments
    var start = -math.pi / 2;
    for (var i = 0; i < shares.length; i++) {
      final sweep = 2 * math.pi * shares[i] * t;
      if (sweep > gap) {
        canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 14 / 128
            ..color = colors[i % colors.length],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.t != t || o.shares != shares;
}

/// Concentric multi-ring chart matching the reference gauge/rings design:
/// - 3 concentric circular tracks with faint background colors
/// - Rounded-cap foreground progress arcs
/// - Radial scale labels around the perimeter ('300', '50', '100', '150', '200', '250')
/// - Value labels inside the arcs at 3 o'clock ('23', '22', '21' / percentage)
class ConcentricRingsChart extends StatelessWidget {
  const ConcentricRingsChart({
    super.key,
    required this.shares,
    required this.colors,
    this.center,
    this.size = 150,
  });

  final List<double> shares;
  final List<Color> colors;
  final Widget? center;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Motion.of(context, AppMotion.barGrow),
          curve: AppMotion.standard,
          builder: (_, t, child) => CustomPaint(
            painter: _ConcentricRingsPainter(shares, colors, t),
            child: child,
          ),
          child: center != null ? Center(child: center) : null,
        ),
      );
}

class _ConcentricRingsPainter extends CustomPainter {
  _ConcentricRingsPainter(this.shares, this.colors, this.t);

  final List<double> shares;
  final List<Color> colors;
  final double t;

  static const _scaleNumbers = ['300', '50', '100', '150', '200', '250'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final count = math.min(shares.length, 3);
    if (count == 0) return;

    // 1. Scale markers around the perimeter at 60-degree increments
    // Top is 300, followed clockwise by 50, 100, 150, 200, 250
    final numberRadius = size.width / 2 - 7;
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + (i * math.pi / 3);
      final x = center.dx + numberRadius * math.cos(angle);
      final y = center.dy + numberRadius * math.sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: _scaleNumbers[i],
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2238),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // 2. Concentric rings radii and stroke width
    const strokeWidth = 8.5;
    const gap = 3.5;
    final r0 = (size.width / 2) - 21.0; // Outer ring center radius ~54px

    for (var i = 0; i < count; i++) {
      final r = r0 - i * (strokeWidth + gap);
      final color = colors[i % colors.length];
      final rect = Rect.fromCircle(center: center, radius: r);

      // (a) Faint background circular track (full 360)
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = color.withValues(alpha: 0.16),
      );

      // (b) Active arc with rounded ends
      final share = shares[i].clamp(0.0, 1.0);
      final sweep = 2 * math.pi * share * t;

      if (sweep > 0.04) {
        canvas.drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }

      // (c) Number label at 3 o'clock (horizontal right) inside the ring
      final pctText = '${(shares[i] * 100).round()}';
      final reached3oclock = sweep >= (math.pi / 2);
      final textColor = reached3oclock ? const Color(0xFFFFFFFF) : color;

      final labelTp = TextPainter(
        text: TextSpan(
          text: pctText,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = center.dx + r - labelTp.width / 2;
      final labelY = center.dy - labelTp.height / 2;
      labelTp.paint(canvas, Offset(labelX, labelY));
    }
  }

  @override
  bool shouldRepaint(_ConcentricRingsPainter o) =>
      o.t != t || o.shares != shares || o.colors != colors;
}

/// Interlocking rounded-bulb donut chart matching the modern reference design:
/// - Slices interlock smoothly with convex caps and concave cutouts
/// - Optional centered summary (e.g. total expenses)
/// - Thin divider line between interlocking slices
/// - Fluid ease-out rotation & scale entrance animation
class InterlockingDonutChart extends StatelessWidget {
  const InterlockingDonutChart({
    super.key,
    required this.shares,
    required this.colors,
    this.center,
    this.size = 144,
    this.innerRadiusRatio = 0.46,
    this.showLabels = false,
    this.separatorWidth = 2.5,
    this.separatorColor = AppColors.white,
  });

  final List<double> shares;
  final List<Color> colors;
  final Widget? center;
  final double size;
  final double innerRadiusRatio;
  final bool showLabels;
  final double separatorWidth;
  final Color separatorColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => CustomPaint(
            painter: _InterlockingDonutPainter(
              shares: shares,
              colors: colors,
              t: t,
              innerRadiusRatio: innerRadiusRatio,
              showLabels: showLabels,
              separatorWidth: separatorWidth,
              separatorColor: separatorColor,
            ),
            child: child,
          ),
          child: center != null
              ? Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutBack,
                    builder: (_, ct, c) => Transform.scale(
                      scale: 0.82 + 0.18 * ct,
                      child: Opacity(opacity: ct.clamp(0.0, 1.0), child: c),
                    ),
                    child: center,
                  ),
                )
              : null,
        ),
      );
}

class _InterlockingDonutPainter extends CustomPainter {
  _InterlockingDonutPainter({
    required this.shares,
    required this.colors,
    required this.t,
    required this.innerRadiusRatio,
    required this.showLabels,
    required this.separatorWidth,
    required this.separatorColor,
  });

  final List<double> shares;
  final List<Color> colors;
  final double t;
  final double innerRadiusRatio;
  final bool showLabels;
  final double separatorWidth;
  final Color separatorColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (shares.isEmpty) return;

    final center = size.center(Offset.zero);
    final cx = center.dx;
    final cy = center.dy;

    final rOuter = size.width / 2 - 2.0;
    final rInner = rOuter * innerRadiusRatio;
    final w = rOuter - rInner;
    final rCap = w / 2;
    final rMid = (rOuter + rInner) / 2;

    final validShares = <double>[];
    for (final s in shares) {
      if (s > 0) validShares.add(s);
    }
    if (validShares.isEmpty) return;

    final totalShare = validShares.fold<double>(0, (a, b) => a + b);
    if (totalShare <= 0) return;

    final count = validShares.length;

    // Fluid entrance: subtle scale & rotation
    final scale = 0.90 + 0.10 * t;
    final rotation = (1.0 - t) * 0.15;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.rotate(rotation);
    canvas.translate(-cx, -cy);

    if (count == 1) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = colors.first;
      canvas.drawCircle(center, rMid, p);
      if (showLabels && t > 0.35) {
        _drawLabel(canvas, Offset(cx, cy - rMid), '100%', colors.first, t, size.width);
      }
      canvas.restore();
      return;
    }

    final slicePaths = <Path>[];
    // Start at -pi / 2 (top 12 o'clock)
    var startAngle = -math.pi / 2;

    for (var i = 0; i < count; i++) {
      final rawShare = validShares[i] / totalShare;
      final sweepAngle = 2 * math.pi * rawShare;
      final endAngle = startAngle + sweepAngle;
      final color = colors[i % colors.length];

      final path = Path();
      final pOuterStart = Offset(
        cx + rOuter * math.cos(startAngle),
        cy + rOuter * math.sin(startAngle),
      );
      path.moveTo(pOuterStart.dx, pOuterStart.dy);

      // 1. Outer arc clockwise
      path.arcTo(
        Rect.fromCircle(center: center, radius: rOuter),
        startAngle,
        sweepAngle,
        false,
      );

      // 2. Convex cap at endAngle (bulges forward clockwise)
      final cEnd = Offset(
        cx + rMid * math.cos(endAngle),
        cy + rMid * math.sin(endAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: cEnd, radius: rCap),
        endAngle,
        math.pi,
        false,
      );

      // 3. Inner arc counter-clockwise back to startAngle
      path.arcTo(
        Rect.fromCircle(center: center, radius: rInner),
        endAngle,
        -sweepAngle,
        false,
      );

      // 4. Concave cutout at startAngle (indents forward into slice)
      final cStart = Offset(
        cx + rMid * math.cos(startAngle),
        cy + rMid * math.sin(startAngle),
      );
      path.arcTo(
        Rect.fromCircle(center: cStart, radius: rCap),
        startAngle + math.pi,
        -math.pi,
        false,
      );

      path.close();
      slicePaths.add(path);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color
        ..isAntiAlias = true;
      canvas.drawPath(path, fillPaint);

      // 5. Percentage text label at the slice center (if enabled)
      if (showLabels && t > 0.35) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelPos = Offset(
          cx + rMid * math.cos(midAngle),
          cy + rMid * math.sin(midAngle),
        );
        final pctText = '${(rawShare * 100).round()}%';
        _drawLabel(canvas, labelPos, pctText, color, t, size.width);
      }

      startAngle = endAngle;
    }

    // Draw ultra-smooth, anti-aliased white borders around each slice
    if (separatorWidth > 0 && count > 1) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = separatorWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = separatorColor
        ..isAntiAlias = true;

      for (final p in slicePaths) {
        canvas.drawPath(p, borderPaint);
      }
    }

    canvas.restore();
  }

  void _drawLabel(
    Canvas canvas,
    Offset pos,
    String text,
    Color sliceColor,
    double t,
    double size,
  ) {
    final alpha = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
    final isLight = sliceColor.computeLuminance() > 0.45;
    final textColor = (isLight ? AppColors.ink : AppColors.white).withValues(alpha: alpha);

    final fontSize = (size * 0.082).clamp(10.0, 14.0);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(pos.dx - painter.width / 2, pos.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_InterlockingDonutPainter o) =>
      o.t != t ||
      o.shares != shares ||
      o.colors != colors ||
      o.innerRadiusRatio != innerRadiusRatio ||
      o.showLabels != showLabels ||
      o.separatorWidth != separatorWidth ||
      o.separatorColor != separatorColor;
}

