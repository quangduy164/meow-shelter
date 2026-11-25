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

/// Small red paper lantern hanging from [tip] on a short cord; [scale] is
/// the art scale and [swing] a gentle sway in radians.
void paintRodLantern(Canvas c, Offset tip,
    {double scale = 1, double swing = 0}) {
  c.save();
  c.translate(tip.dx, tip.dy);
  c.scale(scale);
  c.rotate(swing);
  c.drawLine(
      Offset.zero,
      const Offset(0, 7),
      Paint()
        ..color = const Color(0xFF4A2E1D)
        ..strokeWidth = 1.2);
  c.drawCircle(
      const Offset(0, 14), 13, Paint()..color = const Color(0x55FFC870));
  final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 14), width: 11, height: 13),
      const Radius.circular(5));
  c.drawRRect(body, Paint()..color = const Color(0xFFE0533D));
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 14), width: 5, height: 9),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFD27A));
  for (final dy in [-1.0, 1.0]) {
    c.drawLine(
        Offset(-4.5, 14 + dy * 3),
        Offset(4.5, 14 + dy * 3),
        Paint()
          ..color = const Color(0x66802A1E)
          ..strokeWidth = .7);
  }
  final cap = Paint()..color = const Color(0xFFD9A441);
  c.drawRect(const Rect.fromLTWH(-3.5, 6.5, 7, 2.2), cap);
  c.drawRect(const Rect.fromLTWH(-3.5, 19.5, 7, 2.2), cap);
  c.drawLine(
      const Offset(0, 21.5),
      const Offset(0, 25),
      Paint()
        ..color = const Color(0xFFE0533D)
        ..strokeWidth = 1.4);
  c.restore();
}
