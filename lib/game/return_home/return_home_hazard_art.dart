import 'dart:math';

import 'package:flutter/painting.dart';

/// Vector art for each hazard. Every painter assumes the canvas origin sits at
/// the hazard's center, which [ReturnHomeObstacle] sets up once.
///
/// A new hazard is one painter here plus one hitbox in the obstacle.
void paintSpikes(Canvas canvas) {
  const ink = Color(0xFF3B2E2A);
  final outline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round;
  canvas.drawOval(const Rect.fromLTWH(-19, 8, 38, 7),
      Paint()..color = const Color(0x3D4B392C));
  // Four steel spikes, each with a lit left face and a shaded right face.
  for (final x in const [-12.0, -4.0, 4.0, 12.0]) {
    final tall = x.abs() < 8 ? -13.0 : -9.0;
    canvas.drawPath(
        Path()
          ..moveTo(x - 4.5, 5)
          ..lineTo(x, tall)
          ..lineTo(x, 5)
          ..close(),
        Paint()..color = const Color(0xFFC9CED4));
    canvas.drawPath(
        Path()
          ..moveTo(x, tall)
          ..lineTo(x + 4.5, 5)
          ..lineTo(x, 5)
          ..close(),
        Paint()..color = const Color(0xFF7D848D));
    canvas.drawPath(
        Path()
          ..moveTo(x - 4.5, 5)
          ..lineTo(x, tall)
          ..lineTo(x + 4.5, 5),
        outline);
  }
  final plank = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-17, 4, 34, 8), const Radius.circular(3));
  canvas.drawRRect(plank, Paint()..color = const Color(0xFFB9773F));
  canvas.drawLine(
      const Offset(-14, 6.5),
      const Offset(14, 6.5),
      Paint()
        ..color = const Color(0xFFD9995A)
        ..strokeWidth = 1.6);
  canvas.drawRRect(plank, outline);
  for (final x in const [-13.0, 13.0]) {
    canvas.drawCircle(Offset(x, 8), 1.3, Paint()..color = ink);
  }
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
  double shadowDx = 0,
  required double shadowDy,
  required double shadowDepth,
}) {
  final shadow = .25 + shadowDepth * .75;
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset(shadowDx, shadowDy),
          width: 22 + 26 * shadow,
          height: 8),
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
  // Shadow stays on the ground; only the trunk turns.
  canvas.drawOval(
      vertical
          ? const Rect.fromLTWH(-13, -30, 26, 64)
          : const Rect.fromLTWH(-34, 9, 66, 9),
      Paint()..color = const Color(0x3D4B392C));
  canvas.save();
  if (vertical) canvas.rotate(pi / 2);
  const ink = Color(0xFF4A2B1C);
  final outline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  final trunk = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-30, -10, 60, 22), const Radius.circular(10));
  canvas.drawRRect(trunk, Paint()..color = const Color(0xFF8F5A36));
  canvas.save();
  canvas.clipRRect(trunk);
  canvas.drawRect(const Rect.fromLTWH(-30, -10, 60, 7),
      Paint()..color = const Color(0xFFB27848));
  canvas.drawRect(const Rect.fromLTWH(-30, 6, 60, 6),
      Paint()..color = const Color(0xFF6E4127));
  final bark = Paint()
    ..color = const Color(0xFF5B3520)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (final x in const [-12.0, 2.0, 16.0]) {
    canvas.drawPath(
        Path()
          ..moveTo(x, -6)
          ..quadraticBezierTo(x + 3, 1, x, 8),
        bark);
  }
  canvas.restore();
  canvas.drawRRect(trunk, outline);
  // Small leafy twig on top.
  canvas.drawLine(const Offset(10, -10), const Offset(14, -16), outline);
  canvas.drawOval(const Rect.fromLTWH(13, -21, 8, 5),
      Paint()..color = const Color(0xFF7FA35A));
  canvas.drawOval(
      const Rect.fromLTWH(13, -21, 8, 5), outline..strokeWidth = 1.5);
  // Cut end with growth rings.
  final cap =
      Rect.fromCenter(center: const Offset(-29, 1), width: 14, height: 22);
  canvas.drawOval(cap, Paint()..color = const Color(0xFFE2B57A));
  final ring = Paint()
    ..color = const Color(0xFFB27848)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(-29, 1), width: 8, height: 14),
      ring);
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(-29, 1), width: 3, height: 6), ring);
  canvas.drawOval(cap, outline..strokeWidth = 2.2);
  canvas.restore();
}

/// A red river crab seen from above-front: legs tick while it walks, claws
/// open and snap while it rests at the lane edge.
void paintCrab(Canvas canvas, {required double walk, required bool resting}) {
  const shell = Color(0xFFE0583F);
  const shellLight = Color(0xFFF58A6C);
  const ink = Color(0xFF5A2418);
  final outline = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 9), width: 40, height: 9),
      Paint()..color = const Color(0x334B392C));

  // Legs: three per side, alternating lift while walking.
  final leg = Paint()
    ..color = ink
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  for (final side in const [-1.0, 1.0]) {
    for (var i = 0; i < 3; i++) {
      final lift = resting ? 0.0 : sin(walk + i * 2.1 + side) * 2.5;
      final root = Offset(side * 9, 1.0 + i * 3);
      final knee = Offset(side * (16 + i), -2.0 + i * 3 + lift);
      final foot = Offset(side * (20 + i * 1.5), 6.0 + i * 2 + lift);
      canvas.drawLine(root, knee, leg);
      canvas.drawLine(knee, foot, leg);
    }
  }

  // Claws on short arms; they open wide and snap when resting.
  final open = resting ? (.5 + .5 * sin(walk)) : .25;
  for (final side in const [-1.0, 1.0]) {
    canvas.drawLine(Offset(side * 8, -4), Offset(side * 15, -11), leg);
    canvas.save();
    canvas.translate(side * 16, -14);
    final pincer = Path()
      ..moveTo(0, 3)
      ..quadraticBezierTo(side * -7, -2, side * -3, -9)
      ..lineTo(side * -1, -3 + open * -2)
      ..lineTo(side * 1, -4 - open * 4)
      ..quadraticBezierTo(side * 7, -6, side * 5, 1)
      ..close();
    canvas.drawPath(pincer, Paint()..color = shell);
    canvas.drawPath(pincer, outline);
    canvas.restore();
  }

  // Shell.
  final body =
      Rect.fromCenter(center: const Offset(0, 2), width: 28, height: 18);
  canvas.drawOval(body, Paint()..color = shell);
  canvas.drawOval(
      Rect.fromCenter(center: const Offset(-3, -1), width: 14, height: 6),
      Paint()..color = shellLight);
  canvas.drawOval(body, outline);

  // Eye stalks.
  for (final side in const [-1.0, 1.0]) {
    canvas.drawLine(Offset(side * 4, -6), Offset(side * 5, -11), outline);
    canvas.drawCircle(
        Offset(side * 5, -12), 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(Offset(side * 5, -12), 3, outline..strokeWidth = 1.4);
    canvas.drawCircle(Offset(side * 5.4, -12), 1.4, Paint()..color = ink);
    outline.strokeWidth = 2;
  }
}
