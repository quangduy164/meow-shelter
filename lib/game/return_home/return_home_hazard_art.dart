import 'dart:math';

import 'package:flutter/painting.dart';

/// Vector art for each hazard. Every painter assumes the canvas origin sits at
/// the hazard's center, which [ReturnHomeObstacle] sets up once.
///
/// A new hazard is one painter here plus one hitbox in the obstacle.
void paintSpikes(Canvas canvas) {
  canvas.drawOval(const Rect.fromLTWH(-17, 8, 34, 8),
      Paint()..color = const Color(0x3D4B392C));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-17, 3, 34, 10), const Radius.circular(5)),
      Paint()..color = const Color(0xFFD58A3E));
  final spikes = Path()
    ..moveTo(-14, 5)
    ..lineTo(-8, -14)
    ..lineTo(-2, 5)
    ..lineTo(4, -16)
    ..lineTo(10, 5)
    ..lineTo(15, -12)
    ..lineTo(19, 5)
    ..close();
  canvas.drawPath(spikes, Paint()..color = const Color(0xFF6C6870));
  final edge = Paint()
    ..color = const Color(0xFFE6E0E4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(-8, -13), const Offset(-4, 3), edge);
  canvas.drawLine(const Offset(4, -15), const Offset(8, 3), edge);
  canvas.drawLine(const Offset(15, -11), const Offset(17, 3), edge);
  canvas.drawLine(
      const Offset(-14, 8),
      const Offset(14, 8),
      Paint()
        ..color = const Color(0xFFE9A65A)
        ..strokeWidth = 2);
}

/// Rolling boulder. [spin] is the component's rotation: surface details turn
/// with it, while the ground shadow and the sun highlight stay upright.
void paintRock(Canvas canvas, double spin) {
  const outlineColor = Color(0xFF3F4448);
  canvas.save();
  canvas.rotate(-spin);
  canvas.drawOval(const Rect.fromLTWH(-19, 13, 38, 9),
      Paint()..color = const Color(0x40403020));
  canvas.restore();

  final boulder = Path()
    ..moveTo(-19, 2)
    ..cubicTo(-21, -12, -9, -20, 2, -19)
    ..cubicTo(14, -18, 21, -8, 19, 3)
    ..cubicTo(18, 14, 8, 20, -2, 19)
    ..cubicTo(-12, 18, -18, 12, -19, 2)
    ..close();
  canvas.drawPath(boulder, Paint()..color = const Color(0xFF8A9096));
  canvas.save();
  canvas.clipPath(boulder);
  // Lower half darker so the rock reads as round.
  canvas.save();
  canvas.rotate(-spin);
  canvas.drawOval(const Rect.fromLTWH(-24, 2, 48, 30),
      Paint()..color = const Color(0xFF6E757B));
  canvas.restore();
  canvas.drawPath(
      Path()
        ..moveTo(-12, -16)
        ..quadraticBezierTo(-4, -22, 6, -18)
        ..quadraticBezierTo(0, -12, -8, -11)
        ..close(),
      Paint()..color = const Color(0xFF7FA35A));
  final crack = Paint()
    ..color = outlineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(
      Path()
        ..moveTo(4, -4)
        ..lineTo(10, 1)
        ..lineTo(8, 8)
        ..moveTo(10, 1)
        ..lineTo(15, 0),
      crack);
  canvas.drawPath(
      Path()
        ..moveTo(-13, 6)
        ..lineTo(-7, 9)
        ..lineTo(-6, 14),
      crack);
  canvas.drawCircle(const Offset(-2, -2), 1.6, Paint()..color = outlineColor);
  canvas.restore();

  canvas.save();
  canvas.rotate(-spin);
  canvas.drawOval(const Rect.fromLTWH(-12, -14, 10, 6),
      Paint()..color = const Color(0x88FFFFFF));
  canvas.restore();
  canvas.drawPath(
      boulder,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round);
}

/// The ground shadow swells as the bird dips: that is the warning the player
/// has to read before committing to a dodge.
void paintBird(
  Canvas canvas, {
  required double flap,
  required double tilt,
  required double shadowDy,
  required double shadowDepth,
}) {
  final shadow = .25 + shadowDepth * .75;
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, shadowDy), width: 22 + 26 * shadow, height: 8),
      Paint()
        ..color = Color.fromARGB((12 + 34 * shadow).round(), 0x4B, 0x39, 0x2C));
  canvas.save();
  canvas.rotate(tilt);
  const ink = Color(0xFF2B3340);
  final outline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  const feather = Color(0xFF4A5A73);
  const featherDark = Color(0xFF34425A);

  Path wing(double lift) => Path()
    ..moveTo(-2, -3)
    ..quadraticBezierTo(6, -6 - 12 * lift, 18, -4 - 16 * lift)
    ..quadraticBezierTo(14, -1 - 6 * lift, 17, 1 - 6 * lift)
    ..quadraticBezierTo(8, 3, -2, 3)
    ..close();
  void drawWing(double lift, Color color) {
    final path = wing(lift);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, outline);
  }

  // Far wing beats slightly behind the near one.
  drawWing(sin(flap - .6), featherDark);

  final tail = Path()
    ..moveTo(10, -3)
    ..lineTo(22, -7)
    ..lineTo(20, -1)
    ..lineTo(23, 4)
    ..lineTo(10, 3)
    ..close();
  canvas.drawPath(tail, Paint()..color = featherDark);
  canvas.drawPath(tail, outline);

  final feet = Paint()
    ..color = const Color(0xFFE0A23C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(-2, 7), const Offset(1, 11), feet);
  canvas.drawLine(const Offset(3, 7), const Offset(6, 11), feet);

  final body = Path()
    ..moveTo(-14, -2)
    ..cubicTo(-14, -11, 2, -11, 11, -4)
    ..cubicTo(14, 2, 8, 9, -3, 8)
    ..cubicTo(-12, 7, -14, 3, -14, -2)
    ..close();
  canvas.drawPath(body, Paint()..color = feather);
  canvas.save();
  canvas.clipPath(body);
  canvas.drawOval(const Rect.fromLTWH(-12, 1, 20, 12),
      Paint()..color = const Color(0xFFDCE4EE));
  canvas.restore();
  canvas.drawPath(body, outline);

  canvas.drawPath(
      Path()
        ..moveTo(-13, -5)
        ..lineTo(-22, -2)
        ..lineTo(-13, 1)
        ..close(),
      Paint()..color = const Color(0xFFF2B33D));
  canvas.drawPath(
      Path()
        ..moveTo(-13, -5)
        ..lineTo(-22, -2)
        ..lineTo(-13, 1)
        ..close(),
      outline..strokeWidth = 1.5);

  canvas.drawCircle(
      const Offset(-8, -4), 3.2, Paint()..color = const Color(0xFFFFFFFF));
  canvas.drawCircle(const Offset(-8.8, -3.6), 1.6, Paint()..color = ink);
  // Frown: this bird means business.
  canvas.drawLine(const Offset(-11.5, -9), const Offset(-5, -6.5),
      outline..strokeWidth = 2);

  drawWing(sin(flap), feather);
  canvas.restore();
}

void paintLog(Canvas canvas, {required bool vertical}) {
  canvas.save();
  if (vertical) canvas.rotate(pi / 2);
  canvas.drawOval(const Rect.fromLTWH(-34, 11, 68, 12),
      Paint()..color = const Color(0x3D4B392C));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-31, -10, 62, 22), const Radius.circular(8)),
      Paint()..color = const Color(0xFF8B5635));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-27, -7, 54, 7), const Radius.circular(4)),
      Paint()..color = const Color(0xFFB87543));
  canvas.drawCircle(
      const Offset(-27, 1), 11, Paint()..color = const Color(0xFFC98A54));
  final rings = Paint()
    ..color = const Color(0xFF8B5635)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  canvas.drawOval(const Rect.fromLTWH(-34, -7, 14, 16), rings);
  canvas.drawOval(const Rect.fromLTWH(-31, -4, 8, 10), rings);
  final bark = Paint()
    ..color = const Color(0xFF653D2A)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(-15, -5), const Offset(-8, 7), bark);
  canvas.drawLine(const Offset(2, -6), const Offset(8, 6), bark);
  canvas.drawLine(const Offset(17, -5), const Offset(22, 5), bark);
  canvas.restore();
}
