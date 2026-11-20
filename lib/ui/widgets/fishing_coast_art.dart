import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import 'fishing_island_art.dart';

/// Coastal landmarks share river-world coordinates and the cached backdrop.
void paintFishingCoast(Canvas canvas, double left, double right) {
  final paint = Paint();
  for (var i = 0;
      i < ((FishingRiver.length - FishingRiver.seaStart) / 360).ceil();
      i++) {
    final x = 3630 + i * 360.0;
    if (x < left - 100 || x > right + 100) continue;
    _palm(canvas, Offset(x, FishingRiver.bottom(x) + 86), i);
  }
  // Distant islands are silhouettes beyond the open sea horizon, not a bank.
  for (final x in [4250.0, 5080.0]) {
    if (x < left - 160 || x > right + 160) continue;
    canvas.drawPath(
        Path()
          ..moveTo(x - 130, 111)
          ..quadraticBezierTo(x - 85, 82, x - 35, 97)
          ..quadraticBezierTo(x + 20, 65, x + 58, 94)
          ..quadraticBezierTo(x + 100, 98, x + 135, 111)
          ..close(),
        paint..color = const Color(0xFFA4C7BC));
    for (var i = 0; i < 3; i++) {
      final p = Offset(x + i * 41 - 35, 54 + i % 2 * 10.0);
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 7, p.dy + 3)
            ..quadraticBezierTo(p.dx - 3, p.dy - 3, p.dx, p.dy + 2)
            ..quadraticBezierTo(p.dx + 4, p.dy - 3, p.dx + 9, p.dy + 3),
          Paint()
            ..color = const Color(0xFF758E8C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8);
    }
  }
  final rng = math.Random(928);
  for (var i = 0; i < 190; i++) {
    final x = 3500 + rng.nextDouble() * (FishingRiver.length - 3500);
    final y = FishingRiver.bottom(x) + 17 + rng.nextDouble() * 100;
    if (x < left || x > right || y > FishingRiver.height) continue;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 3, height: 1.5),
        paint
          ..color =
              i.isEven ? const Color(0x66BBA478) : const Color(0x88FFF0CA));
    if (i % 13 == 0) _shell(canvas, Offset(x, y));
  }
  for (final x in [3940.0, 4790.0, 6500.0, 7850.0]) {
    if (x < left - 100 || x > right + 100) continue;
    final p = Offset(x, FishingRiver.bottom(x) + 53);
    _umbrella(canvas, p);
    _chair(canvas, p + const Offset(30, 18));
    _chair(canvas, p + const Offset(-28, 17));
  }
  if (left < 4520 && right > 4280) {
    _lighthouse(canvas, Offset(4390, FishingRiver.bottom(4390) + 77));
  }
  if (left < 5300 && right > 5100) {
    final p = Offset(5190, FishingRiver.bottom(5190) + 25);
    canvas.drawOval(
        Rect.fromCenter(center: p + const Offset(2, 7), width: 100, height: 17),
        paint..color = const Color(0x337E7859));
    canvas.drawPath(
        Path()
          ..moveTo(p.dx - 47, p.dy - 5)
          ..quadraticBezierTo(p.dx, p.dy + 37, p.dx + 48, p.dy - 5)
          ..lineTo(p.dx + 41, p.dy - 16)
          ..lineTo(p.dx - 39, p.dy - 16)
          ..close(),
        paint..color = const Color(0xFF8A6651));
    canvas.drawOval(
        Rect.fromCenter(center: p - const Offset(0, 12), width: 82, height: 18),
        paint..color = const Color(0xFFE4B77F));
    canvas.drawOval(
        Rect.fromCenter(center: p - const Offset(0, 12), width: 65, height: 10),
        paint..color = const Color(0xFF9D7854));
  }
}

void paintFishingIsland(Canvas c, Offset center, double radius) {
  final p = Paint();
  c.drawCircle(center, radius + 32, p..color = const Color(0x3353C4C1));
  c.drawCircle(center, radius + 16, p..color = const Color(0x555FD0BE));
  c.drawCircle(center + const Offset(2, 6), radius + 3,
      p..color = const Color(0x55608E85));
  c.drawCircle(center, radius, p..color = const Color(0xFFDECA96));
  c.drawCircle(center, radius - 10, p..color = const Color(0xFFF1DCA9));
  c.save();
  c.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 12)));
  c.translate(center.dx, center.dy);
  // Uneven grassy terraces leave a broad sandy beach around the south coast.
  final meadow = Path()
    ..moveTo(-330, -40)
    ..cubicTo(-360, -180, -210, -340, -65, -315)
    ..cubicTo(80, -365, 300, -240, 290, -80)
    ..cubicTo(375, 55, 250, 200, 95, 175)
    ..cubicTo(-70, 265, -280, 185, -330, -40)
    ..close();
  c.drawPath(meadow, p..color = const Color(0xFFBCC783));
  c.drawPath(
      Path()
        ..moveTo(-275, -90)
        ..cubicTo(-260, -260, -90, -300, 60, -265)
        ..cubicTo(240, -250, 295, -90, 190, 15)
        ..cubicTo(40, 100, -245, 70, -275, -90)
        ..close(),
      p..color = const Color(0xFFA5BC76));
  c.drawOval(const Rect.fromLTWH(-120, -90, 275, 245),
      p..color = const Color(0xFFCAD28F));
  // A loop and a branch connect the landing, central clearing and open beach.
  final paths = Path()
    ..moveTo(-410, 30)
    ..cubicTo(-270, 10, -220, 125, -80, 90)
    ..cubicTo(20, 45, 115, 120, 240, 220)
    ..moveTo(-80, 90)
    ..cubicTo(50, -25, 200, -85, 175, -220)
    ..moveTo(-180, 65)
    ..cubicTo(-240, -35, -170, -130, -90, -190);
  c.drawPath(
      paths,
      Paint()
        ..color = const Color(0x55A29B64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 37
        ..strokeCap = StrokeCap.round);
  c.drawPath(
      paths,
      Paint()
        ..color = const Color(0xFFE4D6A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 29
        ..strokeCap = StrokeCap.round);
  final rng = math.Random(6307);
  for (var i = 0; i < 650; i++) {
    final point =
        Offset(rng.nextDouble() * 860 - 430, rng.nextDouble() * 860 - 430);
    if (point.distance > radius - 22) continue;
    c.drawOval(
        Rect.fromCenter(
            center: point, width: 2 + rng.nextDouble() * 3, height: 1.5),
        p
          ..color = point.dy > 160
              ? const Color(0x44BDA77E)
              : const Color(0x44829D60));
  }
  // Grass tufts and little flowers outline the clearing, keeping its middle free.
  for (var i = 0; i < 35; i++) {
    final a = i * 2.4;
    final point = Offset(math.cos(a) * (170 + i % 3 * 35),
        math.sin(a) * (120 + i % 4 * 25) - 35);
    c.drawLine(
        point,
        point + const Offset(-3, -6),
        Paint()
          ..color = const Color(0xFF7E9C5D)
          ..strokeWidth = 1.5);
    if (i % 3 == 0) {
      c.drawCircle(
          point - const Offset(2, 7),
          2.5,
          p
            ..color =
                i.isEven ? const Color(0xFFF3E8AE) : const Color(0xFFE6B1A0));
    }
  }
  // Small beach landmarks: driftwood, smooth stones and shell fragments.
  for (final base in [const Offset(-150, 290), const Offset(285, 110)]) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(-.25);
    c.drawLine(
        const Offset(-26, 0),
        const Offset(29, 0),
        Paint()
          ..color = const Color(0xFFB49B71)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    c.drawLine(
        const Offset(-20, -2),
        const Offset(23, -2),
        Paint()
          ..color = const Color(0xFFE1C694)
          ..strokeWidth = 2);
    c.restore();
  }
  for (var i = 0; i < 18; i++) {
    final a = i * .43;
    final point = Offset(math.cos(a), math.sin(a)) * (radius - 37 - i % 3 * 12);
    if (i % 3 == 0) {
      _shell(c, point);
    } else {
      c.drawOval(
          Rect.fromCenter(center: point, width: 8 + i % 3 * 3, height: 5),
          p..color = const Color(0xFFCABA8D));
    }
  }
  c.restore();
  // Coconut grove stays in the northern zone; beach and central lawn remain open.
  for (final base in [
    const Offset(-190, -210),
    const Offset(-105, -250),
    const Offset(-15, -225),
    const Offset(85, -235),
    const Offset(180, -175),
    const Offset(225, -85),
    const Offset(-280, -40),
    const Offset(265, 55)
  ]) {
    _palm(c, center + base, base.dx.toInt());
  }
  _islandRocks(c, center + const Offset(275, -180));
  _islandRocks(c, center + const Offset(-265, 190));
  paintIslandDock(c);
  // Cargo and mooring rope make the landing easy to recognise from the water.
  final dock = center + Offset(-radius + 45, 68);
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: dock, width: 25, height: 22),
          const Radius.circular(3)),
      p..color = const Color(0xFFB68D5D));
  c.drawLine(
      dock + const Offset(-10, -8),
      dock + const Offset(10, 8),
      Paint()
        ..color = const Color(0xFF84653F)
        ..strokeWidth = 2);
  c.drawOval(
      Rect.fromCenter(
          center: dock + const Offset(33, 0), width: 24, height: 13),
      Paint()
        ..color = const Color(0xFFB9A175)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
}

void _islandRocks(Canvas c, Offset p) {
  for (var i = 0; i < 3; i++) {
    final q = p + Offset((i - 1) * 22.0, math.sin(i * 2) * 10);
    c.drawOval(
        Rect.fromCenter(center: q + const Offset(0, 4), width: 38, height: 15),
        Paint()..color = const Color(0x33878C65));
    c.drawPath(
        Path()
          ..moveTo(q.dx - 16, q.dy)
          ..lineTo(q.dx - 10, q.dy - 19)
          ..lineTo(q.dx + 8, q.dy - 22)
          ..lineTo(q.dx + 20, q.dy - 1)
          ..close(),
        Paint()..color = const Color(0xFFA6B19A));
    c.drawLine(
        q + const Offset(-7, -17),
        q + const Offset(5, -20),
        Paint()
          ..color = const Color(0xFFD1D3B4)
          ..strokeWidth = 2);
  }
}

void _palm(Canvas c, Offset base, int seed) {
  final bend = seed.isEven ? 15.0 : -15.0;
  final crown = base + Offset(bend, -92);
  final trunk = Path()
    ..moveTo(base.dx - 6, base.dy)
    ..quadraticBezierTo(
        base.dx + bend * .6 - 6, base.dy - 43, crown.dx - 3, crown.dy)
    ..lineTo(crown.dx + 3, crown.dy)
    ..quadraticBezierTo(
        base.dx + bend * .6 + 4, base.dy - 43, base.dx + 7, base.dy)
    ..close();
  c.drawOval(Rect.fromCenter(center: base, width: 58, height: 10),
      Paint()..color = const Color(0x337C7853));
  c.drawPath(trunk, Paint()..color = const Color(0xFFAA8958));
  for (var i = 1; i < 8; i++) {
    final p = Offset.lerp(base, crown, i / 8)!;
    c.drawLine(
        p - const Offset(4, 0),
        p + const Offset(4, 2),
        Paint()
          ..color = const Color(0xFF7E724A)
          ..strokeWidth = 2);
  }
  for (var i = 0; i < 7; i++) {
    final a = -math.pi + i * math.pi / 6;
    final tip = crown + Offset(math.cos(a) * 57, math.sin(a) * 31 + 10);
    final leaf = Path()
      ..moveTo(crown.dx, crown.dy)
      ..quadraticBezierTo((crown.dx + tip.dx) / 2,
          math.min(crown.dy, tip.dy) - 20, tip.dx, tip.dy)
      ..quadraticBezierTo((crown.dx + tip.dx) / 2, (crown.dy + tip.dy) / 2 + 1,
          crown.dx, crown.dy);
    c.drawPath(
        leaf,
        Paint()
          ..color =
              i.isEven ? const Color(0xFF57966B) : const Color(0xFF77AD72));
    c.drawLine(
        crown,
        tip,
        Paint()
          ..color = const Color(0xFF457D59)
          ..strokeWidth = 1);
  }
  for (final dx in [-5.0, 4.0]) {
    c.drawCircle(
        crown + Offset(dx, 7), 5.5, Paint()..color = const Color(0xFF8E744C));
  }
}

void _lighthouse(Canvas c, Offset p) {
  c.save();
  c.translate(p.dx, p.dy);
  final paint = Paint();
  c.drawOval(const Rect.fromLTWH(-55, -1, 115, 18),
      paint..color = const Color(0x337F805D));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-38, -3, 76, 10), const Radius.circular(4)),
      paint..color = const Color(0xFFB3A98B));
  final tower = Path()
    ..moveTo(-29, 0)
    ..lineTo(-18, -111)
    ..lineTo(18, -111)
    ..lineTo(29, 0)
    ..close();
  c.drawPath(tower, paint..color = const Color(0xFFFFEACA));
  c.save();
  c.clipPath(tower);
  for (final y in [-83.0, -36.0]) {
    c.drawRect(
        Rect.fromLTWH(-35, y, 70, 22), paint..color = const Color(0xFFCD7F69));
  }
  c.drawRect(const Rect.fromLTWH(8, -111, 25, 112),
      paint..color = const Color(0x22725343));
  c.restore();
  c.drawPath(
      tower,
      Paint()
        ..color = const Color(0xFF8A8068)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -27, 18, 28), const Radius.circular(7)),
      paint..color = const Color(0xFF657F7E));
  c.drawOval(const Rect.fromLTWH(-5, -66, 10, 14),
      paint..color = const Color(0xFF6A9CA3));
  c.drawRect(const Rect.fromLTWH(-23, -139, 46, 28),
      paint..color = const Color(0xFFB1D0CB));
  c.drawRect(const Rect.fromLTWH(-15, -134, 30, 18),
      paint..color = const Color(0xFFFFDE86));
  for (final x in [-21.0, 0.0, 21.0]) {
    c.drawLine(
        Offset(x, -139),
        Offset(x, -110),
        Paint()
          ..color = const Color(0xFF6D7E74)
          ..strokeWidth = 3);
  }
  c.drawPath(
      Path()
        ..moveTo(-32, -140)
        ..lineTo(0, -163)
        ..lineTo(32, -140)
        ..close(),
      paint..color = const Color(0xFFA36254));
  c.drawRect(const Rect.fromLTWH(-30, -113, 60, 6),
      paint..color = const Color(0xFF899786));
  c.restore();
}

void _umbrella(Canvas c, Offset p) {
  c.drawLine(
      p,
      p - const Offset(0, 58),
      Paint()
        ..color = const Color(0xFF9C835D)
        ..strokeWidth = 3);
  for (var i = 0; i < 4; i++) {
    c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 69)
          ..quadraticBezierTo(
              p.dx + (i - 2) * 20, p.dy - 63, p.dx + (i - 2) * 20, p.dy - 41)
          ..lineTo(p.dx + (i - 1) * 20, p.dy - 41)
          ..quadraticBezierTo(p.dx + (i - 1) * 16, p.dy - 65, p.dx, p.dy - 69)
          ..close(),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFE6A173) : const Color(0xFFFFE6AD));
  }
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(3, 5), width: 80, height: 16),
      Paint()..color = const Color(0x22797457));
}

void _chair(Canvas c, Offset p) {
  final frame = Paint()
    ..color = const Color(0xFF9F855F)
    ..strokeWidth = 2.5;
  c.drawLine(p - const Offset(10, 3), p + const Offset(10, 9), frame);
  c.drawLine(p + const Offset(10, -3), p - const Offset(10, -9), frame);
  c.drawPath(
      Path()
        ..moveTo(p.dx - 13, p.dy - 25)
        ..lineTo(p.dx + 9, p.dy - 25)
        ..lineTo(p.dx + 15, p.dy + 1)
        ..lineTo(p.dx - 7, p.dy + 1)
        ..close(),
      Paint()..color = const Color(0xFF83B6B5));
  c.drawLine(
      p - const Offset(2, 25),
      p + const Offset(4, 1),
      Paint()
        ..color = const Color(0xFFE9E9CE)
        ..strokeWidth = 5);
}

void _shell(Canvas c, Offset p) {
  c.drawArc(Rect.fromCenter(center: p, width: 11, height: 9), math.pi, math.pi,
      true, Paint()..color = const Color(0xFFF2D6BF));
  for (var i = 0; i < 3; i++) {
    c.drawLine(
        p,
        p + Offset((i - 1) * 3.0, -4),
        Paint()
          ..color = const Color(0xFFD3AF93)
          ..strokeWidth = .8);
  }
}
