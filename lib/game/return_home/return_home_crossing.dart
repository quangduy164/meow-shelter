import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_road.dart';

/// A shallow stream cutting across the lane. Paws must land on a stone; water
/// costs one heart and sends the cat back to the near bank.
class ReturnHomeCrossing extends PositionComponent {
  ReturnHomeCrossing({required this.road}) : super(priority: 1);

  final ReturnHomeRoad road;
  static const double centerFraction = .64;
  static const double crossingWidth = 176;
  static const double stoneRadius = 25;
  static const _stones = [
    Offset(-.36, -.42),
    Offset(-.12, .30),
    Offset(.12, -.25),
    Offset(.36, .40),
  ];

  double get centerX => road.worldWidth * centerFraction;
  double get left => centerX - crossingWidth / 2;
  double get right => centerX + crossingWidth / 2;
  double get safeBankX => left - 105;

  Iterable<Offset> get stones => _stones.map((s) {
        final x = centerX + s.dx * crossingWidth;
        return Offset(x, road.centerY(x) + s.dy * road.halfWidth(x));
      });

  bool inWater(Rect catBox) {
    final paw = Offset(catBox.center.dx, catBox.bottom - 4);
    if (paw.dx < left || paw.dx > right) return false;
    if (paw.dy < road.topEdge(paw.dx) || paw.dy > road.bottomEdge(paw.dx)) {
      return false;
    }
    return !stones.any((stone) => (stone - paw).distance <= stoneRadius);
  }

  @override
  void render(Canvas canvas) {
    final topL = road.edgePoint(left, -1);
    final topR = road.edgePoint(right, -1);
    final bottomR = road.edgePoint(right, 1);
    final bottomL = road.edgePoint(left, 1);
    final water = Path()
      ..moveTo(topL.dx, topL.dy - 8)
      ..quadraticBezierTo(centerX, topL.dy - 22, topR.dx, topR.dy - 8)
      ..lineTo(bottomR.dx, bottomR.dy + 10)
      ..quadraticBezierTo(centerX, bottomR.dy + 24, bottomL.dx, bottomL.dy + 10)
      ..close();
    canvas.drawPath(water, Paint()..color = const Color(0xFF5FB4D0));
    canvas.drawPath(
        water,
        Paint()
          ..color = const Color(0x99D7F5F2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    final ripple = Paint()
      ..color = const Color(0x88EFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = left + 20 + i * (crossingWidth - 40) / 8;
      final y = road.centerY(x) + sin(i * 1.7) * road.halfWidth(x) * .65;
      canvas.drawLine(Offset(x - 9, y), Offset(x + 9, y), ripple);
    }
    for (final stone in stones) {
      canvas.drawOval(
          Rect.fromCenter(
              center: stone + const Offset(0, 7), width: 54, height: 18),
          Paint()..color = const Color(0x44406270));
      canvas.drawOval(Rect.fromCenter(center: stone, width: 52, height: 34),
          Paint()..color = const Color(0xFF8D9690));
      canvas.drawOval(
          Rect.fromCenter(
              center: stone + const Offset(-7, -5), width: 25, height: 11),
          Paint()..color = const Color(0xFFC1C7BE));
    }
  }
}
