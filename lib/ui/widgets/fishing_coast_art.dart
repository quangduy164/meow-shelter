import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_island.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_island_art.dart';
import 'fishing_volcano_art.dart';

/// Coastal landmarks share river-world coordinates and the cached backdrop.
void paintFishingCoast(Canvas canvas, double left, double right) {
  final paint = Paint();
  for (var i = 0;
      i < ((FishingRiver.length - FishingRiver.seaStart) / 360).ceil();
      i++) {
    final x = FishingRiver.seaStart + 30 + i * 360.0;
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
    final x = FishingRiver.seaStart -
        100 +
        rng.nextDouble() * (FishingRiver.length - FishingRiver.seaStart + 100);
    final y = FishingRiver.bottom(x) + 17 + rng.nextDouble() * 100;
    if (x < left || x > right || y > FishingRiver.height) continue;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 3, height: 1.5),
        paint
          ..color =
              i.isEven ? const Color(0x66BBA478) : const Color(0x88FFF0CA));
    if (i % 13 == 0) _shell(canvas, Offset(x, y));
  }
  for (final x in [5740.0, 6590.0, 9450.0, 10250.0]) {
    if (x < left - 100 || x > right + 100) continue;
    final p = Offset(x, FishingRiver.bottom(x) + 53);
    _umbrella(canvas, p);
    _chair(canvas, p + const Offset(30, 18));
    _chair(canvas, p + const Offset(-28, 17));
  }
  if (left < 6320 && right > 6080) {
    _lighthouse(canvas, Offset(6190, FishingRiver.bottom(6190) + 77));
  }
  if (left < 7100 && right > 6900) {
    final p = Offset(6990, FishingRiver.bottom(6990) + 25);
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
  const island = fishingSeaIsland;
  // Shallow reef, wet sand and dry sand follow the irregular coastline.
  c.drawPath(island.outline(grow: 46), p..color = const Color(0x2253C4C1));
  c.drawPath(island.outline(grow: 28), p..color = const Color(0x3353C4C1));
  c.drawPath(island.outline(grow: 14), p..color = const Color(0x555FD0BE));
  c.drawPath(island.outline(grow: 3).shift(const Offset(2, 6)),
      p..color = const Color(0x55608E85));
  // Darker wet sand at the waterline, a lace of foam, then dry sand.
  c.drawPath(island.outline(), p..color = const Color(0xFFCDB37E));
  c.drawPath(island.outline(grow: -16), p..color = const Color(0xFFF1DCA9));
  c.drawPath(
      island.outline(grow: 1),
      Paint()
        ..color = const Color(0xCCF7FBF4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  c.save();
  c.clipPath(island.outline(grow: -12));
  c.translate(center.dx, center.dy);
  // Grass follows the coastline inland, nudged north so the south keeps a
  // broad beach: outlined lawn, a darker terrace and a bright clearing.
  Path inland(double grow, double scale, Offset shift) =>
      island.outline(grow: grow, scale: scale).shift(shift - island.center);
  final lawn = inland(-95, 1, const Offset(0, -35));
  c.drawPath(
      lawn.shift(const Offset(0, 5)), p..color = const Color(0x33806A3E));
  c.drawPath(lawn, p..color = const Color(0xFFA9C278));
  c.drawPath(
      lawn,
      Paint()
        ..color = const Color(0xFF6E8A4E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  paintIslandStreamBed(c);
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
    final point = Offset(math.cos(a), math.sin(a)) *
        (island.radiusAt(a) - 37 - i % 3 * 12);
    if (i % 3 == 0) {
      _shell(c, point);
    } else {
      c.drawOval(
          Rect.fromCenter(center: point, width: 8 + i % 3 * 3, height: 5),
          p..color = const Color(0xFFCABA8D));
    }
  }
  c.restore();
  // A few palms frame the beach; the volcano owns the middle.
  for (final base in const [
    Offset(-250, -250),
    Offset(-60, -330),
    Offset(-340, -60),
  ]) {
    _palm(c, center + base, base.dx.toInt());
  }
  paintVolcano(c, FishingIslandVisit.mountain);
  // The climbable lighthouse on the east headland.
  c.save();
  c.translate(
      FishingIslandVisit.lighthouse.dx, FishingIslandVisit.lighthouse.dy);
  c.scale(FishingIslandVisit.lighthouseScale);
  _lighthouse(c, Offset.zero);
  c.restore();
  for (final base in const [
    Offset(350, 150),
    Offset(-300, 170),
    Offset(200, 300),
  ]) {
    _palm(c, center + base, base.dx.toInt());
  }
  _campfire(c, center + const Offset(-210, 240));
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

/// Stone ring with crossed logs and two log seats; the flame is live.
void _campfire(Canvas c, Offset p) {
  c.drawOval(Rect.fromCenter(center: p, width: 70, height: 34),
      Paint()..color = const Color(0x33806A3E));
  for (var i = 0; i < 9; i++) {
    final a = i * math.pi * 2 / 9;
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset(math.cos(a) * 24, math.sin(a) * 12),
            width: 12,
            height: 9),
        Paint()
          ..color =
              i.isEven ? const Color(0xFF8E8577) : const Color(0xFFA59C8C));
  }
  c.drawOval(Rect.fromCenter(center: p, width: 34, height: 16),
      Paint()..color = const Color(0xFF3E342A));
  for (final d in [-1.0, 1.0]) {
    c.drawLine(
        p + Offset(-14 * d, 5),
        p + Offset(14 * d, -5),
        Paint()
          ..color = const Color(0xFF7A5634)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
  }
  for (final (q, angle) in const [
    (Offset(-48, 18), .3),
    (Offset(46, 20), -.25)
  ]) {
    c.save();
    c.translate(p.dx + q.dx, p.dy + q.dy);
    c.rotate(angle);
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-24, -7, 48, 14), const Radius.circular(7)),
        Paint()..color = const Color(0xFF8A6440));
    c.drawOval(const Rect.fromLTWH(18, -7, 10, 14),
        Paint()..color = const Color(0xFFD8B987));
    c.restore();
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
