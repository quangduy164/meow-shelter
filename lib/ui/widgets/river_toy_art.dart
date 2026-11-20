import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/river_frog.dart';

void paintPaperBoat(Canvas c, Offset p) {
  c.save();
  c.translate(p.dx, p.dy);
  c.drawOval(const Rect.fromLTWH(-25, 3, 50, 12),
      Paint()..color = const Color(0x22406769));
  final hull = Path()
    ..moveTo(-25, -2)
    ..lineTo(25, -2)
    ..lineTo(13, 12)
    ..lineTo(-13, 12)
    ..close();
  c.drawPath(hull, Paint()..color = const Color(0xFFF3D8B3));
  c.drawPath(
      Path()
        ..moveTo(-25, -2)
        ..lineTo(0, 6)
        ..lineTo(-13, 12)
        ..close(),
      Paint()..color = const Color(0xFFD3B28F));
  c.drawPath(
      Path()
        ..moveTo(-18, -2)
        ..lineTo(0, -24)
        ..lineTo(0, 6)
        ..close(),
      Paint()..color = const Color(0xFFFFF2D7));
  c.drawPath(
      Path()
        ..moveTo(0, -24)
        ..lineTo(18, -2)
        ..lineTo(0, 6)
        ..close(),
      Paint()..color = const Color(0xFFE2C6A2));
  c.drawPath(
      hull,
      Paint()
        ..color = const Color(0xFFAA8C72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  c.drawLine(
      const Offset(0, -22),
      const Offset(0, 5),
      Paint()
        ..color = const Color(0xFFBEA082)
        ..strokeWidth = 1);
  c.restore();
}

void paintRiverFrog(Canvas c, RiverFrog frog, double clock, {double bob = 0}) {
  final p = frog.position;
  if (frog.phase == RiverFrogPhase.submerged) {
    if (frog.elapsed > 1.2) return;
    final t = frog.elapsed / 1.2;
    for (var i = 0; i < 2; i++) {
      c.drawOval(
          Rect.fromCenter(
              center: p,
              width: 18 + t * 55 + i * 12,
              height: 9 + t * 24 + i * 5),
          Paint()
            ..color = Color.fromRGBO(228, 252, 231, (1 - t) * .75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
    }
    if (t < .45) {
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi / 4;
        c.drawCircle(
            p +
                Offset(math.cos(a) * t * 58,
                    -math.sin(a) * math.sin(t / .45 * math.pi) * 22),
            2,
            Paint()..color = const Color(0xAAE7F6DA));
      }
    }
    return;
  }
  if (frog.airborne) {
    c.drawOval(Rect.fromCenter(center: p, width: 20, height: 8),
        Paint()..color = const Color(0x33426750));
  }
  c.save();
  c.translate(
      p.dx,
      p.dy -
          frog.jumpHeight -
          3 +
          (frog.phase == RiverFrogPhase.sitting ? bob : 0));
  if (frog.airborne) c.scale(1.12, 1.15);
  final green = Paint()..color = const Color(0xFF6D9E49);
  for (final side in [-1.0, 1.0]) {
    final foot =
        Offset(side * (frog.airborne ? 16 : 10), frog.airborne ? 11 : 6);
    c.drawLine(
        Offset(side * 7, 2),
        foot,
        green
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    c.drawOval(Rect.fromCenter(center: foot, width: 10, height: 5), green);
  }
  c.drawOval(const Rect.fromLTWH(-10, -9, 20, 18), green);
  c.drawOval(const Rect.fromLTWH(-6, -1, 12, 8),
      Paint()..color = const Color(0xFFBDD28A));
  final blink = (clock + frog.seed * .57) % 5 > 4.8;
  for (final x in [-6.0, 6.0]) {
    c.drawCircle(Offset(x, -8), 5, green);
    if (blink) {
      c.drawLine(
          Offset(x - 2, -9),
          Offset(x + 2, -9),
          Paint()
            ..color = const Color(0xFF314D30)
            ..strokeWidth = 1.4);
    } else {
      c.drawCircle(
          Offset(x, -9), 3.5, Paint()..color = const Color(0xFFFFF0B5));
      c.drawCircle(
          Offset(x, -10), 1.8, Paint()..color = const Color(0xFF314D30));
    }
  }
  c.drawArc(
      const Rect.fromLTWH(-4, -5, 8, 5),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF446839)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  c.restore();
}
