import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_road.dart';

/// A shallow stream cutting across the lane. Paws must land on a stone; water
/// costs one heart and sends the cat back to the near bank.
class ReturnHomeCrossing extends PositionComponent {
  ReturnHomeCrossing({required this.road, required this.centerFraction})
      : super(priority: 1);

  final ReturnHomeRoad road;
  final double centerFraction;
  static const double crossingWidth = 176;

  /// Generous landing radius: neighbouring stones overlap, so there is always
  /// a continuous dry path across, it just zigzags.
  static const double stoneRadius = 28;
  static const _stones = [
    Offset(-.38, -.15),
    Offset(-.19, .15),
    Offset(0, -.15),
    Offset(.19, .15),
    Offset(.38, -.15),
  ];

  double get centerX => road.worldWidth * centerFraction;
  double get left => centerX - crossingWidth / 2;
  double get right => centerX + crossingWidth / 2;
  double get safeBankX => left - 105;

  Iterable<Offset> get stones => _stones.map((s) {
        final x = centerX + s.dx * crossingWidth;
        return Offset(x, road.centerY(x) + s.dy * road.halfWidth(x));
      });

  /// Drawn stone is a 60x40 ellipse; landing uses the same ellipse plus a
  /// small grace margin so what looks dry is dry.
  static const double stoneRx = 30 + 6;
  static const double stoneRy = 20 + 6;

  bool _onStone(Offset p) => stones.any((s) {
        final dx = (p.dx - s.dx) / stoneRx;
        final dy = (p.dy - s.dy) / stoneRy;
        return dx * dx + dy * dy <= 1;
      });

  /// Water surface at a point: inside the crossing, on the lane, off stones.
  bool isWater(Offset p) {
    if (p.dx < left || p.dx > right) return false;
    if (p.dy < road.topEdge(p.dx) || p.dy > road.bottomEdge(p.dx)) return false;
    return !_onStone(p);
  }

  /// The cat falls only if its whole paw line is over water: one paw on a
  /// stone is enough to stand.
  bool inWater(Rect catBox) {
    final y = catBox.bottom - 4;
    return [catBox.left + 6, catBox.center.dx, catBox.right - 6]
        .every((x) => isWater(Offset(x, y)));
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
              center: stone + const Offset(0, 8), width: 62, height: 20),
          Paint()..color = const Color(0x44406270));
      canvas.drawOval(Rect.fromCenter(center: stone, width: 60, height: 40),
          Paint()..color = const Color(0xFF8D9690));
      canvas.drawOval(
          Rect.fromCenter(
              center: stone + const Offset(-7, -5), width: 25, height: 11),
          Paint()..color = const Color(0xFFC1C7BE));
    }
  }
}
