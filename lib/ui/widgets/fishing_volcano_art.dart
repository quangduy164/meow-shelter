import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_island.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_art_kit.dart';
import 'fishing_rock_art.dart';

/// The island's dormant volcano, seen from above: jungle around its foot,
/// stacked rock tiers rising north, a steaming crater, and a waterfall that
/// drops into a pool and runs to the south beach as a stream.

Size get _r => FishingIslandVisit.mountainRadii;

/// Waterfall x offset from the mountain centre, top and pool (relative).
const _fallX = 232.0, _fallTop = -6.0, _poolY = 158.0;

Path _poly(Offset o, List<Offset> pts) =>
    Path()..addPolygon([for (final p in pts) o + p], true);

/// Rough outline of everything the mountain covers, in world space; the
/// water surface layer leaves this area alone.
Path mountainSilhouette() {
  final m = FishingIslandVisit.mountain;
  return Path()
    ..addOval(
        Rect.fromCenter(center: m, width: _r.width * 2, height: _r.height * 2))
    ..addPath(
        _poly(m, const [
          Offset(-290, 40),
          Offset(-160, -300),
          Offset(-60, -480),
          Offset(70, -470),
          Offset(205, -300),
          Offset(300, 40),
        ]),
        Offset.zero);
}

void _peak(Canvas c, Offset o, List<Offset> outline, int apex, int lit,
    int shade, int snow,
    {double snowDepth = 60}) {
  final body = _poly(o, outline);
  c.drawPath(body, fillPaint(lit));
  c.save();
  c.clipPath(body);
  final top = o + outline[apex];
  // Shaded east face: everything right of the apex ridge.
  c.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + 400, top.dy)
        ..lineTo(top.dx + 400, o.dy + 200)
        ..lineTo(top.dx + 40, o.dy + 200)
        ..close(),
      fillPaint(shade));
  // Facets and cracks.
  for (var i = 0; i < 9; i++) {
    final x = top.dx - 120 + i * 30.0 + artNoise(apex + i, 20) * 12;
    final y0 = top.dy + 40 + artNoise(apex + i, 21) * 60;
    c.drawPath(
        Path()
          ..moveTo(x, y0)
          ..lineTo(x + 10 - artNoise(i, 22) * 20, y0 + 70)
          ..lineTo(x - 6, y0 + 150),
        strokePaint(0x5530282A, 2));
  }
  if (snowDepth > 0) {
    // Snow cap with a jagged lower edge.
    final cap = Path()..moveTo(top.dx - 120, top.dy - 20);
    for (var i = 0; i <= 8; i++) {
      final x = top.dx - 120 + i * 30.0;
      cap.lineTo(
          x, top.dy + snowDepth * (.5 + artNoise(apex * 7 + i, 23) * .7));
    }
    cap
      ..lineTo(top.dx + 120, top.dy - 20)
      ..close();
    c.drawPath(cap, fillPaint(snow));
    c.drawPath(cap.shift(const Offset(18, 0)), fillPaint(0x33557088));
  }
  // Moss tufts on ledges.
  for (var i = 0; i < 6; i++) {
    final p = Offset(top.dx - 80 + artNoise(apex + i, 24) * 160,
        top.dy + 90 + artNoise(apex + i, 25) * 200);
    c.drawOval(Rect.fromCenter(center: p, width: 22, height: 9),
        fillPaint(0xFF5E9A4A));
    c.drawOval(
        Rect.fromCenter(center: p - const Offset(3, 2), width: 12, height: 5),
        fillPaint(0xFF86C062));
  }
  c.restore();
  c.drawPath(body, strokePaint(0xFF231E22, 3));
}

void _pine(Canvas c, Offset base, double s) {
  c.drawOval(
      Rect.fromCenter(
          center: base + Offset(4 * s, 2), width: 34 * s, height: 9 * s),
      fillPaint(0x332A3A20));
  c.drawLine(base, base + Offset(0, -14 * s), strokePaint(0xFF5B3A22, 4 * s));
  for (var i = 0; i < 3; i++) {
    final y = base.dy - 10 * s - i * 18 * s;
    final w = (22 - i * 5) * s;
    final tri = Path()
      ..moveTo(base.dx - w, y)
      ..lineTo(base.dx, y - 30 * s)
      ..lineTo(base.dx + w, y)
      ..close();
    c.drawPath(tri, fillPaint(i.isEven ? 0xFF2F6B3A : 0xFF3A7D42));
    c.drawPath(
        Path()
          ..moveTo(base.dx, y - 30 * s)
          ..lineTo(base.dx + w, y)
          ..lineTo(base.dx + w * .2, y)
          ..close(),
        fillPaint(0x33001A08));
    c.drawPath(tri, strokePaint(0xFF16301C, 1.6));
  }
}

/// Rocky mountain in the style of a painted cartoon massif: blue-grey side
/// peaks, a tall snow-capped main peak, a tan rock spur, a grassy hill with
/// boulders in front, pine stands, a waterfall gorge and the cave mouth.
void paintVolcano(Canvas c, Offset m) {
  final rx = _r.width, ry = _r.height;
  c.drawOval(
      Rect.fromCenter(
          center: m + const Offset(30, 30), width: rx * 2.1, height: ry * 2),
      fillPaint(0x33304A28));
  _peak(
      c,
      m,
      const [
        Offset(-292, 40),
        Offset(-250, -60),
        Offset(-205, -200),
        Offset(-160, -300),
        Offset(-128, -276),
        Offset(-96, -210),
        Offset(-56, -120),
        Offset(-36, 40),
      ],
      3,
      0xFF9DB4BE,
      0xFF5F7C8C,
      0xFFE4F2F6,
      snowDepth: 45);
  _peak(
      c,
      m,
      const [
        Offset(56, 40),
        Offset(110, -120),
        Offset(168, -250),
        Offset(205, -292),
        Offset(236, -242),
        Offset(272, -120),
        Offset(300, 40),
      ],
      3,
      0xFF9DB4BE,
      0xFF5F7C8C,
      0xFFE4F2F6,
      snowDepth: 40);
  _peak(
      c,
      m,
      const [
        Offset(-192, 60),
        Offset(-150, -100),
        Offset(-122, -262),
        Offset(-92, -380),
        Offset(-62, -468),
        Offset(8, -482),
        Offset(70, -456),
        Offset(96, -350),
        Offset(140, -200),
        Offset(186, -40),
        Offset(202, 60),
      ],
      5,
      0xFFA59C92,
      0xFF6E6872,
      0xFFD8EEF4,
      snowDepth: 70);
  _peak(
      c,
      m,
      const [
        Offset(-34, 96),
        Offset(30, -58),
        Offset(70, -172),
        Offset(112, -60),
        Offset(172, 96),
      ],
      2,
      0xFFC4B2A0,
      0xFF8E7C6E,
      0,
      snowDepth: 0);
  // Gorge for the waterfall on the right flank.
  final fall = m + const Offset(_fallX, 0);
  final gorge = Path()
    ..moveTo(fall.dx - 20, m.dy + _fallTop - 8)
    ..lineTo(fall.dx + 20, m.dy + _fallTop - 8)
    ..lineTo(fall.dx + 38, m.dy + _poolY - 4)
    ..lineTo(fall.dx - 38, m.dy + _poolY - 4)
    ..close();
  c.drawPath(gorge, fillPaint(0xFF6E6872));
  c.drawPath(gorge, strokePaint(0xFF231E22, 2.5));
  final pool = Rect.fromCenter(
      center: Offset(fall.dx, m.dy + _poolY), width: 96, height: 40);
  c.drawOval(pool.inflate(6), fillPaint(0xFF8C8577));
  c.drawOval(pool, fillPaint(0xFF5FB6C6));
  c.drawOval(pool.deflate(10).translate(-6, 2), fillPaint(0xFF86D1D8));
  for (var i = 0; i < 7; i++) {
    final a = math.pi * (.12 + i * .13);
    paintBoulder(c, pool.center + Offset(math.cos(a) * 54, math.sin(a) * 24),
        7 + artNoise(i, 5) * 5, 600 + i,
        inWater: false);
  }
  // Grassy hill sweeping across the foot, following the footprint rim.
  final hill = Path()..moveTo(m.dx - 296, m.dy + 40);
  for (final p in const [
    Offset(-240, 2),
    Offset(-160, -10),
    Offset(-80, 22),
    Offset(0, 66),
    Offset(90, 88),
    Offset(170, 76),
    Offset(200, 60),
  ]) {
    hill.lineTo(m.dx + p.dx, m.dy + p.dy);
  }
  for (var i = 0; i <= 24; i++) {
    final a = i / 24 * math.pi;
    final x = math.cos(a) * rx, y = math.sin(a) * ry;
    if (x > 205) continue;
    hill.lineTo(m.dx + x, m.dy + y);
  }
  hill.close();
  c.drawPath(
      hill,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF86C24A), Color(0xFF4E9A3A)])
            .createShader(
                Rect.fromLTRB(m.dx - rx, m.dy - 20, m.dx + rx, m.dy + ry)));
  c.drawPath(hill, strokePaint(0xFF2C5A26, 3));
  for (var i = 0; i < 6; i++) {
    final y = m.dy + 60 + (i % 2) * 18.0;
    c.drawPath(
        Path()
          ..moveTo(m.dx - 240 + i * 60.0, y)
          ..quadraticBezierTo(
              m.dx - 210 + i * 60.0, y - 10, m.dx - 186 + i * 60.0, y + 4),
        strokePaint(0x55B6E07A, 3));
  }
  // Rock outcrops on the slope and stones along its rim.
  for (final (p, r) in const [
    (Offset(-120, 70), 26.0),
    (Offset(-84, 88), 16.0),
    (Offset(10, 128), 24.0),
    (Offset(52, 120), 15.0),
    (Offset(-20, 150), 12.0),
  ]) {
    paintBoulder(c, m + p, r, (p.dx * 7 + p.dy).toInt(), inWater: false);
  }
  for (var i = 0; i < 14; i++) {
    final a = .15 + i * (math.pi - .3) / 13;
    final x = math.cos(a) * rx * .98;
    if (x > 200) continue;
    paintBoulder(c, m + Offset(x, math.sin(a) * ry * .98),
        9 + artNoise(i, 26) * 6, 700 + i,
        inWater: false);
  }
  // Pine stands on both flanks.
  for (final (p, s) in const [
    (Offset(-268, 40), 1.1),
    (Offset(-236, 70), .95),
    (Offset(-280, 96), .85),
    (Offset(-200, 30), .8),
    (Offset(258, 70), 1.0),
    (Offset(284, 100), .85),
    (Offset(176, 104), .8),
  ]) {
    _pine(c, m + p, s);
  }
  // Cave mouth at the south-west foot, framed by boulders.
  final mouth = FishingIslandVisit.caveMouth + const Offset(18, -48);
  final arch = Path()
    ..moveTo(mouth.dx - 34, mouth.dy + 22)
    ..quadraticBezierTo(mouth.dx - 36, mouth.dy - 30, mouth.dx, mouth.dy - 34)
    ..quadraticBezierTo(
        mouth.dx + 36, mouth.dy - 30, mouth.dx + 34, mouth.dy + 22)
    ..close();
  for (var i = 0; i < 7; i++) {
    final a = math.pi + i * math.pi / 6;
    paintBoulder(c, mouth + Offset(math.cos(a) * 44, math.sin(a) * 40 + 10),
        14 + artNoise(i, 27) * 6, 760 + i,
        inWater: false);
  }
  c.drawPath(
      arch,
      Paint()
        ..shader = const RadialGradient(colors: [
          Color(0xFF3A5A70),
          Color(0xFF100C14)
        ], stops: [
          0,
          .7
        ]).createShader(
            Rect.fromCircle(center: mouth + const Offset(0, 6), radius: 40)));
  c.drawPath(arch, strokePaint(0xFF231E22, 3));
}

/// Stream from the plunge pool to the south beach, in island-local space.
final Path islandStream = () {
  final pool = FishingIslandVisit.mountain - fishingSeaIsland.center;
  final start = pool + const Offset(_fallX, _poolY + 14);
  return Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(start.dx - 40, start.dy + 60, start.dx + 70, start.dy + 120,
        start.dx + 20, start.dy + 180)
    ..quadraticBezierTo(
        start.dx, start.dy + 220, start.dx + 30, start.dy + 270);
}();

void paintIslandStreamBed(Canvas c) {
  c.drawPath(islandStream, strokePaint(0xFFC9B27C, 38));
  c.drawPath(islandStream, strokePaint(0xFF4FA9BA, 22));
  c.drawPath(islandStream, strokePaint(0xFF79C9D3, 12));
}

/// Live parts: falling water, foam and mist, a daytime rainbow, crater
/// steam and glints drifting down the stream.
void paintVolcanoLive(Canvas c, double clock, double daylight) {
  final m = FishingIslandVisit.mountain;
  final x = m.dx + _fallX;
  final top = m.dy + _fallTop, bottom = m.dy + _poolY - 8;
  // The sheet widens and ripples as it falls.
  double half(double y) => 16 + (y - top) / (bottom - top) * 14;
  final sheetPath = Path()..moveTo(x - half(top), top);
  for (var y = top; y <= bottom; y += 8) {
    sheetPath.lineTo(x - half(y) + math.sin(clock * 6 + y * .1) * 1.5, y);
  }
  for (var y = bottom; y >= top; y -= 8) {
    sheetPath.lineTo(x + half(y) + math.sin(clock * 6 + y * .13 + 2) * 1.5, y);
  }
  sheetPath.close();
  c.drawPath(sheetPath, fillPaint(0xDDD8F2F8));
  final sheet = Rect.fromLTRB(x - 14, top, x + 14, bottom);
  final streak = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 7; i++) {
    final lx = sheet.left + 4 + i * 4.0;
    for (var j = 0; j < 3; j++) {
      final y =
          top + ((clock * (150 + i * 9) + j * 60 + i * 23) % (bottom - top));
      c.drawLine(Offset(lx, y), Offset(lx, math.min(bottom, y + 16)), streak);
    }
  }
  // Foam ring and mist at the pool.
  final base = Offset(x, bottom + 6);
  for (var i = 0; i < 9; i++) {
    final a = i * math.pi * 2 / 9 + clock * 1.6;
    c.drawCircle(base + Offset(math.cos(a) * 18, math.sin(a) * 6),
        5 + math.sin(clock * 5 + i) * 1.5, fillPaint(0xEEFFFFFF));
  }
  c.drawOval(
      Rect.fromCenter(
          center: base + const Offset(0, -10), width: 120, height: 60),
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)])
                .createShader(Rect.fromCenter(
                    center: base + const Offset(0, -10),
                    width: 120,
                    height: 60)));
  if (daylight > .05) {
    const colors = [
      0xFFFF6B6B,
      0xFFFFB347,
      0xFFFFF176,
      0xFF7BD389,
      0xFF6EC6FF,
      0xFFB39DDB
    ];
    for (var i = 0; i < colors.length; i++) {
      c.drawArc(
          Rect.fromCenter(
              center: base + const Offset(0, -6),
              width: 110 - i * 6.0,
              height: 70 - i * 6.0),
          math.pi * 1.1,
          math.pi * .8,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Color(colors[i]).withValues(alpha: .28 * daylight));
    }
  }
  // Glints drifting down the stream.
  final shift = fishingSeaIsland.center;
  for (final metric in islandStream.computeMetrics()) {
    for (var i = 0; i < 10; i++) {
      final d = (clock * 40 + i * metric.length / 10) % metric.length;
      final tangent = metric.getTangentForOffset(d);
      if (tangent == null) continue;
      final p = tangent.position + shift;
      if (!fishingSeaIsland.contains(p, inset: 20)) continue;
      c.drawCircle(p, 2.2, fillPaint(0xCCFFFFFF));
    }
  }
}
