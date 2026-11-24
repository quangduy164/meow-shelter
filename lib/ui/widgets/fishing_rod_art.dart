import 'dart:math' as math;
import 'package:flutter/painting.dart';

final _twig = Path()
  ..moveTo(0, 0)
  ..quadraticBezierTo(13, -8, 30, -9);
final _leaves = Path()
  ..moveTo(7, -4)
  ..quadraticBezierTo(6, -13, 11, -21)
  ..quadraticBezierTo(15, -10, 7, -4)
  ..close()
  ..moveTo(14, -7)
  ..quadraticBezierTo(17, -19, 29, -23)
  ..quadraticBezierTo(25, -11, 14, -7)
  ..close()
  ..moveTo(22, -9)
  ..quadraticBezierTo(31, -17, 42, -12)
  ..quadraticBezierTo(32, -7, 22, -9)
  ..close()
  ..moveTo(15, -7)
  ..quadraticBezierTo(27, -7, 31, 4)
  ..quadraticBezierTo(18, 1, 15, -7)
  ..close();
final _leafFill = Paint()..color = const Color(0xFF57A544);
final _twigStroke = Paint()
  ..color = const Color(0xFF28663B)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.1
  ..strokeCap = StrokeCap.round;

/// Shared natural bamboo foliage follows the rod's bend and facing.
void paintBambooLeaves(Canvas c, Offset base, Offset direction,
    {double scale = 1, double side = 1}) {
  c.save();
  c.translate(base.dx, base.dy);
  c.rotate(math.atan2(direction.dy, direction.dx));
  c.scale(scale, scale * side);
  c.drawPath(_twig, _twigStroke);
  c.drawPath(_leaves, _leafFill);
  c.drawPath(_leaves, _twigStroke);
  c.restore();
}
