import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import 'fishing_art_kit.dart';

/// Warm, outlined rock art shared by every region so rocks match the ship
/// and island style. All of it is recorded into the cached chunks; the moving
/// foam ring is drawn live by [paintRockFoam].

const _rockTones = [
  (0xFF8E8577, 0xFF5E574E, 0xFFB9AE9A),
  (0xFF968B7A, 0xFF645B4F, 0xFFC2B59D),
  (0xFF85837A, 0xFF57554F, 0xFFB0AEA2),
];

/// A boulder sitting in water: shallow halo, chunky body with a lit top
/// facet, wet waterline, barnacles, optional moss and seaweed, and foam.
/// With [inWater] false it sits on land: ground shadow, no wet line or foam.
void paintBoulder(Canvas c, Offset p, double r, int seed,
    {bool inWater = true}) {
  double n(int k) => artNoise(seed + k, 80);
  final tone = _rockTones[seed.abs() % _rockTones.length];
  if (inWater) {
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset(0, r * .15), width: r * 3.1, height: r * 1.5),
        fillPaint(0x3360D2D0));
  }
  c.drawOval(
      Rect.fromCenter(
          center: p + Offset(r * .14, r * .32), width: r * 2.4, height: r * .9),
      fillPaint(0x40304A48));
  final count = 8 + (n(1) * 3).floor();
  final body = Path();
  final points = <Offset>[];
  for (var i = 0; i < count; i++) {
    final a = -math.pi + i * math.pi * 2 / count + (n(i + 2) - .5) * .35;
    final rr = .82 + n(i + 20) * .3;
    points.add(p +
        Offset(
            math.cos(a) * r * rr * 1.08, math.sin(a) * r * rr * .78 - r * .32));
  }
  body.addPolygon(points, true);
  c.drawPath(body, fillPaint(tone.$1));
  c.save();
  c.clipPath(body);
  // Shadowed right side and underside.
  c.drawOval(
      Rect.fromCenter(
          center: p + Offset(r * .75, r * .1), width: r * 1.6, height: r * 2),
      fillPaint((tone.$2 & 0x00FFFFFF) | 0x99000000));
  c.drawRect(
      Rect.fromLTRB(p.dx - r * 2, p.dy - r * .22, p.dx + r * 2, p.dy + r),
      fillPaint((tone.$2 & 0x00FFFFFF) | 0xCC000000));
  // Lit top facets.
  final top = Offset(p.dx - r * .2, p.dy - r * .62);
  c.drawPath(
      Path()
        ..addPolygon([
          for (final q in points)
            if (q.dy < p.dy - r * .2) top + (q - top) * .62
        ], true),
      fillPaint(tone.$3));
  c.drawPath(
      Path()
        ..moveTo(top.dx - r * .35, top.dy + r * .05)
        ..lineTo(top.dx + r * .05, top.dy - r * .22)
        ..lineTo(top.dx + r * .2, top.dy + r * .02)
        ..close(),
      fillPaint(0x55FFF6E2));
  // Wet waterline.
  if (inWater) {
    c.drawRect(
        Rect.fromLTRB(p.dx - r * 2, p.dy - r * .03, p.dx + r * 2, p.dy + r),
        fillPaint(0xFF46504E));
  }
  // A few scattered barnacles just above the waterline.
  for (var i = 0; i < 4; i++) {
    if (n(i + 32) < .35) continue;
    final q = Offset(p.dx - r * .75 + n(i + 30) * r * 1.5,
        p.dy - r * .08 - n(i + 31) * r * .3);
    c.drawCircle(q, math.max(1.4, r * .06), fillPaint(0xFFD9CFB8));
    c.drawCircle(q, math.max(.6, r * .025), fillPaint(0xFF6B6358));
  }
  c.restore();
  c.drawPath(body, strokePaint(0xFF443E37, math.max(1.6, r * .06)));
  // Crack.
  c.drawPath(
      Path()
        ..moveTo(p.dx + r * .1, p.dy - r * .95)
        ..lineTo(p.dx + r * .22, p.dy - r * .6)
        ..lineTo(p.dx + r * .08, p.dy - r * .35),
      strokePaint(0x88443E37, math.max(1, r * .035)));
  if (n(40) < .55) {
    for (var i = 0; i < 4; i++) {
      c.drawOval(
          Rect.fromCenter(
              center:
                  top + Offset((i - 1.5) * r * .26, r * (.08 + (i % 2) * .06)),
              width: r * .42,
              height: r * .2),
          fillPaint(i.isEven ? 0xFF7E9A5C : 0xFF6C8A4E));
    }
  }
  if (!inWater) return;
  if (n(41) < .5) {
    for (var i = 0; i < 3; i++) {
      final b = Offset(p.dx - r * .5 + i * r * .45, p.dy + r * .02);
      c.drawPath(
          Path()
            ..moveTo(b.dx, b.dy)
            ..quadraticBezierTo(
                b.dx - r * .12, b.dy + r * .2, b.dx + r * .05, b.dy + r * .36),
          strokePaint(0xAA5E7A44, math.max(1.4, r * .06)));
    }
  }
  // Static foam lapping the waterline.
  final foam = strokePaint(0xCCF4FBF8, math.max(1.6, r * .07));
  final ring = Rect.fromCenter(
      center: p + Offset(0, r * .02), width: r * 2.3, height: r * .7);
  c.drawArc(ring, .15, 1.1, false, foam);
  c.drawArc(ring, math.pi - 1.25, 1.0, false, foam);
}

/// Live foam ring pulsing around a rock at the waterline.
void paintRockFoam(Canvas c, Offset p, double r, double clock, int seed) {
  final t = (clock * .45 + artNoise(seed, 90)) % 1;
  c.drawOval(
      Rect.fromCenter(
          center: p + Offset(0, r * .05),
          width: r * (2.3 + t * 1.1),
          height: r * (.75 + t * .4)),
      Paint()
        ..color = Color.fromRGBO(244, 251, 248, (1 - t) * .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

double _cliffHeight(double x) =>
    62 + 26 * math.sin(x / 170) + 14 * math.sin(x / 53 + 1.3);

/// Rocky bay shores: a continuous layered cliff along the north bank (open
/// around the cave inlet) and a stepped rock shelf along the south bank.
void paintCliffBand(Canvas c, double from, double to) {
  const start = FishingRiver.rockyBayStart - 260,
      end = FishingRiver.openSeaStart + 260;
  final a = math.max(from, start), b = math.min(to, end);
  if (a >= b) return;
  for (final (s, e) in [
    (a, math.min(b, FishingRiver.caveStart - 400)),
    (math.max(a, FishingRiver.caveStart + 400), b),
  ]) {
    if (s < e) _northCliff(c, s, e);
  }
  _southShelf(c, a, b);
}

void _northCliff(Canvas c, double s, double e) {
  double base(double x) => FishingRiver.top(x) - 2;
  // Ends slope down instead of stopping in a vertical wall.
  double taper(double x) {
    final t = (math.min(x - s, e - x) / 160).clamp(0.0, 1.0);
    return .15 + .85 * t * t * (3 - 2 * t);
  }

  double rim(double x) => base(x) - _cliffHeight(x) * taper(x);
  final face = bankBand(s, e, rim, base);
  c.drawPath(face, fillPaint(0xFF8F8372));
  c.save();
  c.clipPath(face);
  // Alternating lit facets between vertical cracks.
  for (var x = (s / 46).floor() * 46.0; x < e; x += 46) {
    final w = 46 * (.7 + artNoise(x.toInt(), 3) * .5);
    final r0 = rim(x), b0 = base(x);
    if (artNoise(x.toInt(), 4) < .55) {
      c.drawPath(
          Path()
            ..moveTo(x, r0)
            ..lineTo(x + w * .8, r0 + 4)
            ..lineTo(x + w * .6, b0)
            ..lineTo(x - w * .1, b0)
            ..close(),
          fillPaint(0x40FFF1D6));
    }
    c.drawLine(Offset(x, r0 + 4), Offset(x + 6, b0 - 10),
        strokePaint(0x775A5146, 1.6));
  }
  // Strata following the cliff.
  for (final f in [.3, .55, .8]) {
    final strata = Path();
    for (var x = s; x <= e; x += 8) {
      final y = rim(x) + (base(x) - rim(x)) * f + math.sin(x / 37 + f * 9) * 2;
      x == s ? strata.moveTo(x, y) : strata.lineTo(x, y);
    }
    c.drawPath(strata, strokePaint(0x66574E44, 2));
  }
  // Wet, darker foot of the cliff.
  c.drawPath(bankBand(s, e, (x) => base(x) - 12, base), fillPaint(0xFF5F574D));
  c.restore();
  // Grassy rim with a bumpy edge, small flowers and the outline.
  final grass = Path()..moveTo(s, rim(s) - 16);
  for (var x = s; x <= e; x += 8) {
    grass.lineTo(x, rim(x) - 16);
  }
  for (var x = e; x >= s; x -= 8) {
    grass.lineTo(x, rim(x) + 3 + math.sin(x / 9) * 2.5);
  }
  grass.close();
  c.drawPath(grass, fillPaint(0xFF7F9A5C));
  final edge = Path();
  for (var x = s; x <= e; x += 8) {
    final y = rim(x) + 3 + math.sin(x / 9) * 2.5;
    x == s ? edge.moveTo(x, y) : edge.lineTo(x, y);
  }
  c.drawPath(edge, strokePaint(0xFF4F473E, 2.5));
  for (var x = (s / 37).floor() * 37.0; x < e; x += 37) {
    if (artNoise(x.toInt(), 5) < .35) {
      c.drawCircle(Offset(x, rim(x) - 8), 2.4,
          fillPaint(artNoise(x.toInt(), 6) < .5 ? 0xFFF3E8AE : 0xFFE6A6B6));
    }
  }
  // Foam where waves hit the foot.
  for (var x = (s / 22).floor() * 22.0; x < e; x += 22) {
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x + artNoise(x.toInt(), 7) * 8, base(x) + 5),
            width: 12 + artNoise(x.toInt(), 8) * 10,
            height: 4),
        fillPaint(0xBBF4FBF8));
  }
}

void _southShelf(Canvas c, double s, double e) {
  double lip(double x) => FishingRiver.bottom(x) + 2;
  double step(double x) =>
      FishingRiver.bottom(x) + 64 + 10 * math.sin(x / 120 + .7);
  c.drawPath(bankBand(s, e, lip, step), fillPaint(0xFFB9AC92));
  c.drawPath(bankBand(s, e, lip, (x) => lip(x) + 13), fillPaint(0xFF7A6E5F));
  c.drawPath(bankBand(s, e, step, (x) => step(x) + 9), fillPaint(0xFF8C806D));
  final line = Path();
  for (var x = s; x <= e; x += 8) {
    x == s ? line.moveTo(x, lip(x)) : line.lineTo(x, lip(x));
  }
  c.drawPath(line, strokePaint(0xFF4F473E, 2.5));
  for (var x = (s / 19).floor() * 19.0; x < e; x += 19) {
    final k = x.toInt();
    final q = Offset(x + artNoise(k, 9) * 10,
        lip(x) + 18 + artNoise(k, 10) * (step(x) - lip(x) - 24));
    c.drawOval(
        Rect.fromCenter(center: q, width: 6 + artNoise(k, 11) * 8, height: 4),
        fillPaint(artNoise(k, 12) < .5 ? 0xFF9E927E : 0xFFCFC2A6));
  }
  for (var x = (s / 22).floor() * 22.0; x < e; x += 22) {
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x + artNoise(x.toInt(), 13) * 8, lip(x) - 4),
            width: 12 + artNoise(x.toInt(), 14) * 10,
            height: 4),
        fillPaint(0xBBF4FBF8));
  }
}
