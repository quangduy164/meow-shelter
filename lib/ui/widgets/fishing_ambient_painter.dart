import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../fishing/fishing_lighting.dart';

class FishingAmbientPainter extends CustomPainter {
  const FishingAmbientPainter({required this.clock, required this.lighting});
  final double clock;
  final FishingLighting lighting;

  Offset _flightPosition(int index, double time) {
    final t = time * (.28 + index * .035) + index * 2.1;
    return Offset(
        500 + math.sin(t) * (220 + index * 20) + math.sin(t * 2.3) * 25,
        402 +
            math.sin(t * 2 + index) * (60 + index * 7) +
            math.cos(t * 1.7) * 12);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 600);
    for (var i = 0; i < 3; i++) {
      final position = _flightPosition(i, clock);
      final direction = _flightPosition(i, clock + .03) - position;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(math.atan2(direction.dy, direction.dx) + math.pi / 2);
      final wing = Paint()
        ..color = Color.fromRGBO(237, 249, 226, lighting.daylight * .8);
      final flutter = 2 + math.sin(clock * 32 + i * 2).abs() * 3;
      for (final side in [-1.0, 1.0]) {
        for (final y in [-2.0, 2.0]) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(side * 7, y), width: 13, height: flutter),
              wing);
        }
      }
      canvas.drawLine(
          const Offset(0, -5),
          const Offset(0, 11),
          Paint()
            ..color = Color.fromRGBO(44, 116, 128, lighting.daylight)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(const Offset(0, -5), 2,
          Paint()..color = Color.fromRGBO(51, 83, 69, lighting.daylight));
      canvas.restore();
    }
    for (var i = 0; i < 12; i++) {
      final position = Offset(i.isEven ? 182 : 826, 472) +
          Offset(math.sin(clock * .35 + i * 3.1) * 42,
              math.cos(clock * .5 + i * 2.2) * 34);
      final flicker =
          math.pow((math.sin(clock * 1.6 + i * 2) + 1) / 2, 3).toDouble();
      canvas.drawCircle(
          position,
          1.6,
          Paint()
            ..color =
                Color.fromRGBO(239, 239, 142, lighting.night * flicker * .9));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingAmbientPainter oldDelegate) =>
      clock != oldDelegate.clock || lighting.hour != oldDelegate.lighting.hour;
}
