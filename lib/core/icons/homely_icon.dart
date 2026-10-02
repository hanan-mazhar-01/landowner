import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import 'homely_icons.dart';

export 'homely_icons.dart';

/// Renders a [HomelyIcons] glyph with the design's stroke style.
///
/// Parsed paths are cached per icon so repeated builds never re-parse SVG data.
class HomelyIcon extends StatelessWidget {
  const HomelyIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 2,
    this.rotation = 0,
  });

  final HomelyIcons icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// Rotation in quarter turns expressed as radians (design uses rotate(90deg)).
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final c = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF111830);
    Widget child = CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(icon, c, strokeWidth),
    );
    if (rotation != 0) child = Transform.rotate(angle: rotation, child: child);
    return RepaintBoundary(child: SizedBox.square(dimension: size, child: child));
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color, this.strokeWidth);

  final HomelyIcons icon;
  final Color color;
  final double strokeWidth;

  static final Map<HomelyIcons, Path> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache.putIfAbsent(icon, () => parseSvgPathData(icon.data));
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}
