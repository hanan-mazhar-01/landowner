import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arcTo negative sweep creates valid closed path', () {
    const center = Offset(100, 100);
    const rOuter = 70.0;
    const rInner = 38.0;
    const rCap = (rOuter - rInner) / 2;
    const rMid = (rOuter + rInner) / 2;

    const startAngle = 0.0;
    const sweepAngle = math.pi / 2;
    const endAngle = startAngle + sweepAngle;

    final path = Path();
    final pOuterStart = Offset(
      center.dx + rOuter * math.cos(startAngle),
      center.dy + rOuter * math.sin(startAngle),
    );
    path.moveTo(pOuterStart.dx, pOuterStart.dy);

    path.arcTo(
      Rect.fromCircle(center: center, radius: rOuter),
      startAngle,
      sweepAngle,
      false,
    );

    final cEnd = Offset(
      center.dx + rMid * math.cos(endAngle),
      center.dy + rMid * math.sin(endAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: cEnd, radius: rCap),
      endAngle,
      math.pi,
      false,
    );

    path.arcTo(
      Rect.fromCircle(center: center, radius: rInner),
      endAngle,
      -sweepAngle,
      false,
    );

    final cStart = Offset(
      center.dx + rMid * math.cos(startAngle),
      center.dy + rMid * math.sin(startAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: cStart, radius: rCap),
      startAngle + math.pi,
      -math.pi,
      false,
    );

    path.close();

    final bounds = path.getBounds();
    expect(bounds.isEmpty, isFalse);
    expect(path.contains(Offset(center.dx + rMid * math.cos(math.pi / 4), center.dy + rMid * math.sin(math.pi / 4))), isTrue);
  });
}
