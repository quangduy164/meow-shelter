import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// One shared rowing cycle keeps the cat, blade and water contact in step.
class FishingOarPose {
  FishingOarPose(double clock,
      {required bool moving, required bool facingRight}) {
    final side = facingRight ? 1.0 : -1.0;
    final cycle = (clock / 1.65) % 1;
    double smooth(double t) {
      t = t.clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    var sweep = 0.0;
    var lift = 0.0;
    wet = 0;
    if (moving) {
      if (cycle < .18) {
        final t = cycle / .18;
        lift = 12 * (1 - smooth(t));
        wet = smooth((t - .65) / .35);
      } else if (cycle < .65) {
        sweep = smooth((cycle - .18) / .47);
        wet = 1;
      } else {
        final t = (cycle - .65) / .35;
        sweep = 1 - smooth(t);
        lift = math.sin(t * math.pi) * 15 + 12 * t;
        wet = 1 - smooth(t / .15);
      }
      hand = Offset(side * (17 - sweep * 8), 12 + sweep * 5);
      final angle = -.15 + sweep * 1.1;
      water =
          hand + Offset(side * math.cos(angle) * 96, math.sin(angle) * 55 + 13);
      blade = water - Offset(0, lift);
      lean = side * (.08 - sweep * .16);
    } else {
      hand = const Offset(-38, 17);
      blade = const Offset(65, 24);
      water = blade;
      lean = 0;
    }
  }

  late final Offset hand, blade, water;
  late final double lean;
  late double wet;
}

void paintFishingOarWater(Canvas canvas, FishingOarPose pose, double clock) {
  if (pose.wet < .05) return;
  for (var i = 0; i < 2; i++) {
    final t = (clock * 1.3 + i * .5) % 1;
    canvas.drawOval(
        Rect.fromCenter(
            center: pose.water + Offset(-t * 9, 3),
            width: 24 + t * 30,
            height: 8 + t * 12),
        Paint()
          ..color = Color.fromRGBO(233, 255, 246, (1 - t) * .65 * pose.wet)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
  }
  for (var i = 0; i < 3; i++) {
    final t = (clock * 1.8 + i / 3) % 1;
    final splash =
        pose.water + Offset((i - 1) * 10 * t, -math.sin(t * math.pi) * 10);
    canvas.drawCircle(
        splash,
        (1 - t) * 2.3,
        Paint()
          ..color = Color.fromRGBO(239, 255, 248, (1 - t) * .8 * pose.wet));
  }
}

void paintFishingOar(Canvas canvas, FishingOarPose pose) {
  final delta = pose.blade - pose.hand;
  final length = delta.distance;
  canvas.save();
  canvas.translate(pose.hand.dx, pose.hand.dy);
  canvas.rotate(math.atan2(delta.dy, delta.dx));
  final stroke = Paint()..strokeCap = StrokeCap.round;
  canvas.drawLine(
      const Offset(-10, 0),
      Offset(length - 12, 0),
      stroke
        ..color = const Color(0xFF674B32)
        ..strokeWidth = 5.5);
  canvas.drawLine(
      const Offset(-8, -1),
      Offset(length - 12, -1),
      stroke
        ..color = const Color(0xFFC59A62)
        ..strokeWidth = 2.6);
  // Broad flat blade with a narrow neck, carved edge and visible wood grain.
  final blade = Path()
    ..moveTo(length - 20, -2.5)
    ..quadraticBezierTo(length - 10, -3, length - 8, -9)
    ..quadraticBezierTo(length + 6, -13, length + 17, -7)
    ..quadraticBezierTo(length + 23, 0, length + 17, 7)
    ..quadraticBezierTo(length + 6, 13, length - 8, 9)
    ..quadraticBezierTo(length - 10, 3, length - 20, 2.5)
    ..close();
  canvas.drawPath(blade, Paint()..color = const Color(0xFFD7AE70));
  canvas.drawPath(
      blade,
      Paint()
        ..color = const Color(0xFF795838)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8);
  canvas.save();
  canvas.clipPath(blade);
  for (final y in [-4.0, 0.0, 4.0]) {
    canvas.drawPath(
        Path()
          ..moveTo(length - 10, y)
          ..quadraticBezierTo(length + 3, y - 2, length + 18, y),
        Paint()
          ..color = const Color(0xFFB58B52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }
  canvas.drawPath(
      Path()
        ..moveTo(length - 5, -7)
        ..quadraticBezierTo(length + 7, -9, length + 14, -5),
      Paint()
        ..color = const Color(0xFFF2D294)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  if (pose.wet > .05) {
    canvas.drawRect(Rect.fromLTWH(length + 3, -12, 20, 24),
        Paint()..color = Color.fromRGBO(57, 128, 128, .23 * pose.wet));
  }
  canvas.restore();
  canvas.restore();
}
