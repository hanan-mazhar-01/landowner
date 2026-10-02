import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';

/// Home portfolio-value chart: smoothed line that draws in over 1400ms, soft
/// blue area, dashed guides and a haloed end marker. Geometry follows the
/// design's 390×170 SVG and scales to the available width.
class ValueLineChart extends StatelessWidget {
  const ValueLineChart({super.key, required this.values, required this.labels, this.height = 170});

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: height,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(values.last),
          tween: Tween(begin: 0, end: 1),
          duration: Motion.of(context, AppMotion.lineDraw),
          curve: AppMotion.draw,
          builder: (_, t, _) => CustomPaint(painter: _LinePainter(values, t)),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < labels.length; i++)
              Text(labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == labels.length - 1 ? FontWeight.w700 : FontWeight.w500,
                    color: i == labels.length - 1 ? AppColors.primary : AppColors.textFaint,
                  )),
          ],
        ),
      ),
    ]);
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.t);
  final List<double> values;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final sx = size.width / 390, sy = size.height / 170;
    final mn = values.reduce((a, b) => a < b ? a : b), mx = values.reduce((a, b) => a > b ? a : b);
    final span = (mx - mn) == 0 ? 1 : mx - mn;
    final n = values.length;
    final pts = [
      for (var i = 0; i < n; i++) Offset((8 + i * (364 / (n - 1))) * sx, (150 - (values[i] - mn) / span * 110) * sy),
    ];

    final dash = Paint()
      ..color = const Color(0xFFDDE3F3)
      ..strokeWidth = 1;
    for (final y in [50.0, 100.0]) {
      _dashed(canvas, Offset(0, y * sy), Offset(size.width, y * sy), 2, 5, dash);
    }

    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < n; i++) {
      final p0 = pts[i - 1], p1 = pts[i], dx = (p1.dx - p0.dx) / 2;
      line.cubicTo(p0.dx + dx, p0.dy, p1.dx - dx, p1.dy, p1.dx, p1.dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height),
            [AppColors.accent.withValues(alpha: .22 * t), AppColors.accent.withValues(alpha: 0)]),
    );

    final metric = line.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );

    final end = pts.last;
    _dashed(canvas, end, Offset(end.dx, size.height), 3, 4,
        Paint()..color = AppColors.accent.withValues(alpha: .3 * t)..strokeWidth = 1);
    canvas.drawCircle(end, 10, Paint()..color = AppColors.accent.withValues(alpha: .15 * t));
    canvas.drawCircle(end, 5, Paint()..color = AppColors.white.withValues(alpha: t));
    canvas.drawCircle(
        end,
        5,
        Paint()
          ..color = AppColors.accent.withValues(alpha: t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6);
  }

  void _dashed(Canvas c, Offset a, Offset b, double on, double off, Paint p) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += on + off) {
      c.drawLine(a + dir * d, a + dir * (d + on).clamp(0, total), p);
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.t != t || o.values != values;
}
