import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import 'fishing_art_kit.dart';
import 'fishing_river_art.dart';

/// Far-land scenery for every region, recorded into the cached chunks.
/// Things sit back from the water so existing bank art keeps its space; a
/// winding footpath runs along each bank and decorations avoid it.
void paintLandScenery(Canvas c, double left, double right) {
  final from = math.max(0.0, left - 160),
      to = math.min(FishingRiver.length, right + 160);
  const step = 175.0;
  for (var i = (from / step).floor(); i * step < to; i++) {
    for (var j = 0; j * step < FishingRiver.height; j++) {
      final k = i * 101 + j * 7;
      if (artNoise(k, 1) < .12) continue;
      final x = i * step + step / 2 + (artNoise(k, 2) - .5) * 100;
      final y = j * step + step / 2 + (artNoise(k, 3) - .5) * 100;
      if (x < from || x > to || y < 300 || y > FishingRiver.height - 70) {
        continue;
      }
      final region = _region(x);
      final margin = _margin(region);
      final north = y < FishingRiver.top(x) - margin.$1;
      final south = y > FishingRiver.bottom(x) + margin.$2;
      if (!north && !south) continue;
      if (north && (x - FishingRiver.caveStart).abs() < 480) continue;
      if (region != _Land.beach && (y - _pathY(x, north)).abs() < 75) {
        continue;
      }
      _feature(c, Offset(x, y), region, k);
    }
  }
}

typedef _Land = FishingLand;

_Land _region(double x) => FishingRegion.alongX(x).land;

/// Footpaths along both banks; drawn early so buildings sit on top.
void paintLandPaths(Canvas c, double left, double right) {
  final from = math.max(0.0, left - 160),
      to = math.min(FishingRiver.length, right + 160);
  for (final north in [true, false]) {
    _footpath(c, from, to, north);
  }
}

final _cottages = fishingCottages();

(double, double) _margin(_Land r) => switch (r) {
      _Land.mangrove => (330.0, 350.0),
      _Land.rocky => (390.0, 330.0),
      _ => (165.0, 185.0),
    };

/// Follows a smoothed bank so side inlets do not bend the path sharply, but
/// never comes closer to the water than the decoration margin.
double _pathY(double x, bool north) {
  final m = _margin(_region(x));
  final wave = math.sin(x / 380) * 45 + math.sin(x / 150) * 10;
  var sum = 0.0;
  for (var i = -4; i <= 4; i++) {
    final q = (x + i * 110).clamp(0.0, FishingRiver.length);
    sum += north ? FishingRiver.top(q) : FishingRiver.bottom(q);
  }
  final bank = sum / 9;
  if (!north) {
    return math.max(
        bank + m.$2 + 175 + wave, FishingRiver.bottom(x) + m.$2 + 40);
  }
  var y = math.min(bank - m.$1 - 175 + wave, FishingRiver.top(x) - m.$1 - 40);
  // Swing behind each cottage: stay above its roof and chimney.
  for (final (base, s) in _cottages) {
    final d = (x - base.dx).abs();
    final t = (1 - (d - 100 * s) / 140).clamp(0.0, 1.0);
    if (t <= 0) continue;
    final clear = base.dy - 150 * s;
    if (y > clear) y += (clear - y) * t * t * (3 - 2 * t);
  }
  return y;
}

void _footpath(Canvas c, double from, double to, bool north) {
  Path? path;
  void flush(_Land r) {
    if (path == null) return;
    switch (r) {
      case _Land.beach:
        break;
      case _Land.rocky:
        c.drawPath(path!, strokePaint(0x55D8D2C0, 30));
      default:
        c.drawPath(path!, strokePaint(0x66B59F72, 34));
        c.drawPath(path!, strokePaint(0xFFC9B48A, 24));
    }
    path = null;
  }

  var last = _region(from);
  for (var x = from; x <= to; x += 12) {
    final r = _region(x);
    if (r != last) {
      flush(last);
      last = r;
    }
    if (north && (x - FishingRiver.caveStart).abs() < 480) {
      flush(r);
      continue;
    }
    final y = _pathY(x, north);
    if (r == _Land.beach) {
      // Paw prints wander along the beach instead of a dirt path.
      if (x.toInt() % 48 < 12) {
        final side = (x.toInt() ~/ 48).isEven ? -7.0 : 7.0;
        _paw(c, Offset(x, y + side));
      }
      continue;
    }
    if (r == _Land.rocky && x.toInt() % 36 < 12) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x, y + (artNoise(x.toInt(), 9) - .5) * 14),
              width: 14,
              height: 8),
          fillPaint(0xFFB7B3A3));
    }
    path == null ? path = (Path()..moveTo(x, y)) : path!.lineTo(x, y);
  }
  flush(last);
}

void _paw(Canvas c, Offset p) {
  final paint = fillPaint(0x33856B45);
  c.drawOval(Rect.fromCenter(center: p, width: 7, height: 6), paint);
  for (var i = 0; i < 3; i++) {
    c.drawCircle(p + Offset(-4 + i * 4.0, -5), 1.8, paint);
  }
}

void _feature(Canvas c, Offset p, _Land region, int k) {
  final pick = artNoise(k, 4);
  c.save();
  c.translate(p.dx, p.dy);
  final s = 1.15 + artNoise(k, 5) * .4;
  c.scale(artNoise(k, 6) < .5 ? -s : s, s);
  // Weighted so landmarks (well, shrine, hut, tower, stall, wreck) stay rare
  // and fillers (trees, flowers, dunes, shrubs) carry most of the land.
  final table = switch (region) {
    _Land.village => [
        (_fruitTree, 3.0),
        (_flowers, 3.0),
        (_garden, 1.6),
        (_haystack, 1.4),
        (_chickens, 1.2),
        (_fence, 1.0),
        (_well, .35),
      ],
    _Land.bamboo => [
        (_bambooGrove, 4.0),
        (_paddy, 1.8),
        (_buffalo, .9),
        (_scarecrow, .8),
        (_shrine, .3),
      ],
    _Land.mangrove => [
        (_reeds, 3.0),
        (_shrimpPond, 1.2),
        (_sampan, .8),
        (_stiltHut, .35),
      ],
    _Land.beach => [
        (_dune, 3.0),
        (_shells, 2.4),
        (_basketBoat, 1.0),
        (_netRack, .8),
        (_sandcastle, .7),
        (_lifeguard, .25),
        (_coconutStall, .25),
      ],
    _Land.rocky => [
        (_shrubs, 3.0),
        (_boulders, 2.2),
        (_cairn, .9),
        (_wreck, .2),
      ],
  };
  var roll = pick * table.fold(0.0, (sum, e) => sum + e.$2);
  for (final (draw, weight) in table) {
    roll -= weight;
    if (roll <= 0) {
      draw(c, k);
      break;
    }
  }
  c.restore();
}

void _shadow(Canvas c, double w, double h) => c.drawOval(
    Rect.fromCenter(center: const Offset(4, 4), width: w, height: h),
    fillPaint(0x2A3E4A2E));

// ---------------------------------------------------------------- village
void _garden(Canvas c, int k) {
  const r = Rect.fromLTWH(-55, -30, 110, 60);
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)),
      fillPaint(0xFF8C6A45));
  for (var i = 0; i < 4; i++) {
    final y = -20 + i * 14.0;
    c.drawLine(Offset(-48, y), Offset(48, y), strokePaint(0xFF735536, 5));
    for (var x = -42.0; x <= 42; x += 12) {
      final color = (i + k).isEven ? 0xFF6FA552 : 0xFF8DBF5E;
      c.drawCircle(Offset(x, y - 2), 4.5, fillPaint(color));
      if (i == 2 && k.isEven) {
        c.drawCircle(Offset(x + 2, y), 2, fillPaint(0xFFE0603E));
      }
    }
  }
  for (var x = -55.0; x <= 55; x += 11) {
    c.drawLine(Offset(x, -34), Offset(x, -24), strokePaint(0xFFB08A5A, 2.5));
    c.drawLine(Offset(x, 26), Offset(x, 36), strokePaint(0xFFB08A5A, 2.5));
  }
}

void _haystack(Canvas c, int k) {
  _shadow(c, 70, 20);
  c.drawPath(
      Path()
        ..moveTo(-32, 6)
        ..quadraticBezierTo(-34, -40, 0, -52)
        ..quadraticBezierTo(34, -40, 32, 6)
        ..close(),
      fillPaint(0xFFE2C266));
  for (var i = 0; i < 6; i++) {
    c.drawLine(Offset(-24 + i * 9.0, -2), Offset(-16 + i * 7.0, -38),
        strokePaint(0xFFC9A64A, 1.6));
  }
  c.drawLine(
      const Offset(0, -52), const Offset(0, -64), strokePaint(0xFF7A5634, 3));
  if (k.isEven) {
    c.drawOval(const Rect.fromLTWH(26, -6, 26, 14), fillPaint(0xFFE2C266));
  }
}

void _well(Canvas c, int k) {
  _shadow(c, 60, 20);
  c.drawOval(const Rect.fromLTWH(-24, -14, 48, 26), fillPaint(0xFF9C9A8E));
  c.drawOval(const Rect.fromLTWH(-17, -10, 34, 17), fillPaint(0xFF2E4D5A));
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    c.drawCircle(Offset(math.cos(a) * 20, math.sin(a) * 10 - 1), 3,
        fillPaint(0xFFB7B5A8));
  }
  c.drawLine(const Offset(-22, -2), const Offset(-22, -48),
      strokePaint(0xFF7A5634, 4));
  c.drawLine(
      const Offset(22, -2), const Offset(22, -48), strokePaint(0xFF7A5634, 4));
  c.drawPath(
      Path()
        ..moveTo(-30, -44)
        ..lineTo(0, -62)
        ..lineTo(30, -44)
        ..close(),
      fillPaint(0xFFA84E3A));
  c.drawLine(
      const Offset(0, -46), const Offset(0, -20), strokePaint(0xFF5B4630, 1.2));
  c.drawRect(const Rect.fromLTWH(-5, -22, 10, 9), fillPaint(0xFF8A6A45));
}

void _fruitTree(Canvas c, int k) {
  _shadow(c, 74, 22);
  c.drawLine(
      const Offset(0, 4), const Offset(0, -36), strokePaint(0xFF7A5634, 8));
  for (var i = 0; i < 6; i++) {
    final a = i * 1.05;
    c.drawCircle(Offset(math.cos(a) * 18, -50 + math.sin(a) * 12), 20,
        fillPaint(i.isEven ? 0xFF5E944C : 0xFF6FA552));
  }
  final fruit = [0xFFF0A23A, 0xFFE0573E, 0xFFF2D04A][k % 3];
  for (var i = 0; i < 7; i++) {
    c.drawCircle(Offset(-22 + i * 7.0, -58 + math.sin(i * 2.1) * 14), 3.6,
        fillPaint(fruit));
  }
  if (k % 3 == 0) {
    c.drawCircle(const Offset(18, 6), 3.6, fillPaint(fruit));
    c.drawCircle(const Offset(-14, 8), 3.6, fillPaint(fruit));
  }
}

void _hen(Canvas c, Offset p, bool white) {
  c.drawOval(Rect.fromCenter(center: p, width: 16, height: 12),
      fillPaint(white ? 0xFFF5F1E4 : 0xFFB0683A));
  c.drawCircle(
      p + const Offset(7, -6), 5, fillPaint(white ? 0xFFF5F1E4 : 0xFFB0683A));
  c.drawCircle(p + const Offset(7, -11), 2.4, fillPaint(0xFFD9402F));
  c.drawPath(
      Path()
        ..moveTo(p.dx + 11, p.dy - 7)
        ..lineTo(p.dx + 15, p.dy - 5)
        ..lineTo(p.dx + 11, p.dy - 4)
        ..close(),
      fillPaint(0xFFE9B949));
  c.drawCircle(p + const Offset(8, -7), 1, fillPaint(0xFF1F1A17));
  c.drawLine(p + const Offset(-1, 5), p + const Offset(-1, 10),
      strokePaint(0xFFE9B949, 1.4));
  c.drawLine(p + const Offset(3, 5), p + const Offset(3, 10),
      strokePaint(0xFFE9B949, 1.4));
}

void _chickens(Canvas c, int k) {
  for (var i = 0; i < 4; i++) {
    _hen(c, Offset(-30 + i * 20.0, (artNoise(k + i, 7) - .5) * 30),
        (k + i) % 3 != 0);
  }
  for (var i = 0; i < 6; i++) {
    c.drawCircle(
        Offset(-24 + i * 9.0, 18 + (i % 2) * 4.0), 1.4, fillPaint(0xFFE6CF8A));
  }
}

void _flowers(Canvas c, int k) {
  const tones = [0xFFE86A8A, 0xFFF2C14A, 0xFFF4F1E6, 0xFFB57BD6];
  for (var i = 0; i < 9; i++) {
    final q =
        Offset((artNoise(k + i, 8) - .5) * 70, (artNoise(k + i, 9) - .5) * 34);
    c.drawCircle(q + const Offset(0, 4), 9, fillPaint(0xFF6E9C4E));
    for (var j = 0; j < 5; j++) {
      final a = j * math.pi * 2 / 5;
      c.drawCircle(q + Offset(math.cos(a) * 3.4, math.sin(a) * 3.4), 2.6,
          fillPaint(tones[(k + i) % tones.length]));
    }
    c.drawCircle(q, 1.8, fillPaint(0xFFF7D25A));
  }
}

void _fence(Canvas c, int k) {
  for (var i = 0; i < 7; i++) {
    final x = -60 + i * 20.0;
    c.drawLine(Offset(x, 4), Offset(x, -26), strokePaint(0xFF9C8A5A, 4));
  }
  c.drawLine(const Offset(-62, -18), const Offset(62, -18),
      strokePaint(0xFFB7A26A, 3));
  c.drawLine(
      const Offset(-62, -6), const Offset(62, -6), strokePaint(0xFFB7A26A, 3));
  if (k.isOdd) _hen(c, const Offset(20, 14), true);
}

// ----------------------------------------------------------------- bamboo
void _bambooGrove(Canvas c, int k) {
  _shadow(c, 100, 24);
  for (var i = 0; i < 9; i++) {
    final x = -40 + i * 10.0 + (artNoise(k + i, 10) - .5) * 8;
    final top = -70 - artNoise(k + i, 11) * 50;
    final lean = (artNoise(k + i, 12) - .5) * 16;
    c.drawLine(
        Offset(x, 4), Offset(x + lean, top), strokePaint(0xFF7FA54E, 4.5));
    for (var y = -14.0; y > top; y -= 16) {
      final t = y / top;
      c.drawLine(Offset(x + lean * t - 3, y), Offset(x + lean * t + 3, y),
          strokePaint(0xFF5E8A3A, 2));
    }
    for (var j = 0; j < 3; j++) {
      final q = Offset(x + lean, top + j * 12);
      final d = (i + j).isEven ? 1.0 : -1.0;
      c.drawPath(
          Path()
            ..moveTo(q.dx, q.dy)
            ..quadraticBezierTo(
                q.dx + d * 10, q.dy - 4, q.dx + d * 18, q.dy + 3)
            ..quadraticBezierTo(q.dx + d * 9, q.dy + 3, q.dx, q.dy)
            ..close(),
          fillPaint((i + j) % 3 == 0 ? 0xFF8DBF5E : 0xFF6FA552));
    }
  }
}

void _shrine(Canvas c, int k) {
  _shadow(c, 60, 18);
  c.drawRect(const Rect.fromLTWH(-20, -10, 40, 14), fillPaint(0xFFB4AA94));
  c.drawRect(const Rect.fromLTWH(-15, -38, 30, 28), fillPaint(0xFFD96A4A));
  c.drawRect(const Rect.fromLTWH(-8, -30, 16, 18), fillPaint(0xFF5B2E22));
  c.drawCircle(const Offset(0, -21), 3, fillPaint(0xFFF2C14A));
  c.drawPath(
      Path()
        ..moveTo(-26, -36)
        ..quadraticBezierTo(0, -58, 26, -36)
        ..lineTo(30, -40)
        ..lineTo(20, -36)
        ..close(),
      fillPaint(0xFF4E6F5E));
  c.drawLine(const Offset(-26, -36), const Offset(-32, -44),
      strokePaint(0xFF4E6F5E, 3));
  c.drawLine(
      const Offset(26, -36), const Offset(32, -44), strokePaint(0xFF4E6F5E, 3));
  for (final x in [-10.0, 10.0]) {
    c.drawLine(Offset(x, 6), Offset(x, -2), strokePaint(0xFFC9A64A, 1.6));
    c.drawCircle(Offset(x, -3), 1.4, fillPaint(0xFFE0603E));
  }
}

void _paddy(Canvas c, int k) {
  for (var row = 0; row < 3; row++) {
    final r = Rect.fromLTWH(-60 + row * 8.0, -36 + row * 24.0, 112, 20);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
        fillPaint(0xFF8F9A62));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(6)),
        fillPaint(row.isEven ? 0xFF7FB0A4 : 0xFF86B5A0));
    for (var x = r.left + 8; x < r.right - 4; x += 9) {
      c.drawLine(Offset(x, r.center.dy + 4), Offset(x - 2, r.center.dy - 6),
          strokePaint(0xFF6FA552, 2));
      c.drawLine(Offset(x, r.center.dy + 4), Offset(x + 3, r.center.dy - 4),
          strokePaint(0xFF8DBF5E, 1.6));
    }
  }
}

void _buffalo(Canvas c, int k) {
  _shadow(c, 80, 20);
  for (final x in [-20.0, -10.0, 14.0, 24.0]) {
    c.drawLine(Offset(x, -6), Offset(x, 8), strokePaint(0xFF4C4A4E, 5));
  }
  c.drawOval(const Rect.fromLTWH(-32, -30, 66, 30), fillPaint(0xFF5A585D));
  c.drawOval(const Rect.fromLTWH(26, -34, 24, 20), fillPaint(0xFF5A585D));
  c.drawOval(const Rect.fromLTWH(40, -24, 12, 10), fillPaint(0xFF7B777A));
  c.drawPath(
      Path()
        ..moveTo(30, -32)
        ..quadraticBezierTo(18, -46, 30, -50)
        ..moveTo(44, -32)
        ..quadraticBezierTo(56, -46, 44, -50),
      strokePaint(0xFFE6DCC6, 3.5));
  c.drawCircle(const Offset(41, -27), 1.6, fillPaint(0xFF1F1A17));
  c.drawLine(const Offset(-32, -20), const Offset(-40, -6),
      strokePaint(0xFF5A585D, 2.5));
  if (k.isEven) {
    // An egret riding on its back.
    c.drawOval(const Rect.fromLTWH(-12, -44, 18, 11), fillPaint(0xFFF7F5EC));
    c.drawCircle(const Offset(6, -48), 4, fillPaint(0xFFF7F5EC));
    c.drawLine(const Offset(9, -48), const Offset(16, -47),
        strokePaint(0xFFE9B949, 1.6));
  }
}

void _scarecrow(Canvas c, int k) {
  _shadow(c, 40, 12);
  c.drawLine(
      const Offset(0, 6), const Offset(0, -60), strokePaint(0xFF7A5634, 4));
  c.drawLine(const Offset(-26, -40), const Offset(26, -40),
      strokePaint(0xFF7A5634, 3.5));
  c.drawPath(
      Path()
        ..moveTo(-20, -44)
        ..lineTo(20, -44)
        ..lineTo(14, -14)
        ..lineTo(-14, -14)
        ..close(),
      fillPaint(0xFF4E7FA8));
  c.drawCircle(const Offset(0, -56), 9, fillPaint(0xFFE6CF8A));
  c.drawPath(
      Path()
        ..moveTo(-18, -58)
        ..lineTo(0, -76)
        ..lineTo(18, -58)
        ..close(),
      fillPaint(0xFFD9B35A));
  c.drawCircle(const Offset(-3, -57), 1.4, fillPaint(0xFF1F1A17));
  c.drawCircle(const Offset(3, -57), 1.4, fillPaint(0xFF1F1A17));
  for (final d in [-1.0, 1.0]) {
    c.drawLine(
        Offset(d * 26, -40), Offset(d * 31, -36), strokePaint(0xFFE2C266, 2));
  }
}

// --------------------------------------------------------------- mangrove
void _shrimpPond(Canvas c, int k) {
  const r = Rect.fromLTWH(-70, -40, 140, 80);
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)),
      fillPaint(0xFF7E7656));
  c.drawRRect(RRect.fromRectAndRadius(r.deflate(8), const Radius.circular(6)),
      fillPaint(0xFF5E8E84));
  for (var i = 0; i < 3; i++) {
    c.drawLine(Offset(-50 + i * 30.0, -18 + i * 10.0),
        Offset(-34 + i * 30.0, -18 + i * 10.0), strokePaint(0x88D8F3FF, 1.4));
  }
  // Paddle-wheel aerator.
  c.drawLine(
      const Offset(10, -6), const Offset(46, -6), strokePaint(0xFF9C8A5A, 3));
  for (final x in [16.0, 40.0]) {
    c.drawOval(Rect.fromCenter(center: Offset(x, -6), width: 10, height: 16),
        fillPaint(0xFF4E7FA8));
  }
  c.drawOval(const Rect.fromLTWH(22, -10, 12, 9), fillPaint(0xFFF4F1E6));
  c.drawLine(const Offset(-70, 40), const Offset(-70, -40),
      strokePaint(0xFF6C6246, 2));
}

void _stiltHut(Canvas c, int k) {
  _shadow(c, 80, 20);
  for (final x in [-26.0, -8.0, 10.0, 28.0]) {
    c.drawLine(Offset(x, 8), Offset(x, -24), strokePaint(0xFF6C6246, 4));
  }
  c.drawRect(const Rect.fromLTWH(-34, -30, 68, 8), fillPaint(0xFF9C8A5A));
  c.drawRect(const Rect.fromLTWH(-26, -58, 52, 28), fillPaint(0xFFB79F6E));
  c.drawRect(const Rect.fromLTWH(-6, -52, 14, 22), fillPaint(0xFF5B4630));
  c.drawPath(
      Path()
        ..moveTo(-38, -56)
        ..lineTo(0, -80)
        ..lineTo(38, -56)
        ..close(),
      fillPaint(0xFFC8B06E));
  for (var i = 0; i < 6; i++) {
    c.drawLine(Offset(-30 + i * 10.0, -59), Offset(-20 + i * 6.0, -73),
        strokePaint(0xFFA8904E, 1.4));
  }
  for (var i = 0; i < 4; i++) {
    c.drawLine(Offset(38, 6 - i * 9.0), Offset(48, 6 - i * 9.0),
        strokePaint(0xFF9C8A5A, 2.5));
  }
}

void _sampan(Canvas c, int k) {
  _shadow(c, 90, 16);
  c.drawPath(
      Path()
        ..moveTo(-46, -6)
        ..quadraticBezierTo(0, 14, 46, -6)
        ..quadraticBezierTo(0, -2, -46, -6)
        ..close(),
      fillPaint(0xFF6E5236));
  c.drawPath(
      Path()
        ..moveTo(-42, -6)
        ..quadraticBezierTo(0, 6, 42, -6)
        ..quadraticBezierTo(0, -10, -42, -6)
        ..close(),
      fillPaint(0xFF9C7A50));
  c.drawLine(
      const Offset(-14, -4), const Offset(-10, 4), strokePaint(0xFF5B4630, 2));
  c.drawLine(
      const Offset(12, -4), const Offset(10, 4), strokePaint(0xFF5B4630, 2));
  c.drawLine(
      const Offset(20, -10), const Offset(62, 8), strokePaint(0xFF9C8A5A, 3));
  c.drawOval(const Rect.fromLTWH(56, 2, 14, 8), fillPaint(0xFF9C8A5A));
}

void _reeds(Canvas c, int k) {
  for (var i = 0; i < 14; i++) {
    final x = -36 + i * 5.5;
    final top = -24 - artNoise(k + i, 13) * 26;
    c.drawLine(Offset(x, 4), Offset(x + 3, top), strokePaint(0xFF7E8A52, 2));
    if (i % 3 == 0) {
      c.drawOval(
          Rect.fromCenter(center: Offset(x + 3, top), width: 5, height: 13),
          fillPaint(0xFF8A6A45));
    }
  }
}

// ------------------------------------------------------------------ beach
void _dune(Canvas c, int k) {
  c.drawOval(const Rect.fromLTWH(-70, -24, 140, 44), fillPaint(0xFFEAD7A4));
  c.drawOval(const Rect.fromLTWH(-56, -30, 100, 30), fillPaint(0xFFF1E1B4));
  for (var i = 0; i < 7; i++) {
    final b = Offset(-40 + i * 13.0, -12 + (i % 2) * 8.0);
    for (final d in [-1.0, 0.0, 1.0]) {
      c.drawLine(b, b + Offset(d * 6, -14 - (i % 3) * 4.0),
          strokePaint(0xFF8FA65A, 1.8));
    }
  }
}

void _sandcastle(Canvas c, int k) {
  _shadow(c, 70, 18);
  c.drawRect(const Rect.fromLTWH(-30, -26, 60, 28), fillPaint(0xFFE2C68A));
  for (final x in [-30.0, 18.0]) {
    c.drawRect(Rect.fromLTWH(x, -44, 12, 46), fillPaint(0xFFD8B97A));
    for (var i = 0; i < 2; i++) {
      c.drawRect(Rect.fromLTWH(x + i * 7.0, -50, 5, 6), fillPaint(0xFFD8B97A));
    }
  }
  c.drawRect(const Rect.fromLTWH(-8, -14, 16, 16), fillPaint(0xFFB79B62));
  c.drawLine(const Offset(24, -50), const Offset(24, -68),
      strokePaint(0xFF7A5634, 1.6));
  c.drawPath(
      Path()
        ..moveTo(24, -68)
        ..lineTo(36, -64)
        ..lineTo(24, -60)
        ..close(),
      fillPaint(0xFFE0573E));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, -8, 18, 14), const Radius.circular(3)),
      fillPaint([0xFF4E9AD0, 0xFFE0573E, 0xFF6FBF6A][k % 3]));
}

void _basketBoat(Canvas c, int k) {
  _shadow(c, 70, 20);
  c.drawOval(const Rect.fromLTWH(-32, -26, 64, 40), fillPaint(0xFF6B4A2C));
  c.drawOval(const Rect.fromLTWH(-28, -24, 56, 34), fillPaint(0xFF8A6A45));
  c.save();
  c.clipPath(Path()..addOval(const Rect.fromLTWH(-28, -24, 56, 34)));
  for (var i = -4; i < 5; i++) {
    c.drawLine(Offset(i * 8.0 - 20, -30), Offset(i * 8.0 + 20, 14),
        strokePaint(0xFF6B4A2C, 1.4));
    c.drawLine(Offset(i * 8.0 + 20, -30), Offset(i * 8.0 - 20, 14),
        strokePaint(0xFF6B4A2C, 1.4));
  }
  c.restore();
  c.drawLine(
      const Offset(22, 4), const Offset(56, -10), strokePaint(0xFF9C8A5A, 3));
}

void _netRack(Canvas c, int k) {
  _shadow(c, 100, 14);
  for (final x in [-46.0, 0.0, 46.0]) {
    c.drawLine(Offset(x, 6), Offset(x, -40), strokePaint(0xFF7A5634, 3.5));
  }
  final net = Path()
    ..moveTo(-46, -38)
    ..quadraticBezierTo(-23, -20, 0, -38)
    ..quadraticBezierTo(23, -20, 46, -38)
    ..lineTo(46, -8)
    ..quadraticBezierTo(23, -2, 0, -10)
    ..quadraticBezierTo(-23, -2, -46, -8)
    ..close();
  c.drawPath(net, fillPaint(0x553E6F86));
  c.save();
  c.clipPath(net);
  for (var x = -50.0; x < 50; x += 6) {
    c.drawLine(Offset(x, -40), Offset(x + 10, 0), strokePaint(0xAA2F5A70, .9));
    c.drawLine(Offset(x + 10, -40), Offset(x, 0), strokePaint(0xAA2F5A70, .9));
  }
  c.restore();
  for (final x in [-30.0, 14.0, 34.0]) {
    c.drawCircle(Offset(x, -8), 3.5, fillPaint(0xFFE0903E));
  }
}

void _lifeguard(Canvas c, int k) {
  _shadow(c, 60, 16);
  for (final x in [-16.0, 16.0]) {
    c.drawLine(Offset(x, 6), Offset(x * .7, -40), strokePaint(0xFFF4F1E6, 4));
  }
  c.drawLine(const Offset(-14, -10), const Offset(14, -10),
      strokePaint(0xFFF4F1E6, 3));
  c.drawRect(const Rect.fromLTWH(-20, -54, 40, 16), fillPaint(0xFFE0573E));
  c.drawRect(const Rect.fromLTWH(-20, -50, 40, 4), fillPaint(0xFFF4F1E6));
  c.drawPath(
      Path()
        ..moveTo(-26, -54)
        ..lineTo(0, -66)
        ..lineTo(26, -54)
        ..close(),
      fillPaint(0xFFF4F1E6));
  c.drawLine(const Offset(24, -54), const Offset(24, -78),
      strokePaint(0xFF7A5634, 1.6));
  c.drawRect(const Rect.fromLTWH(24, -78, 14, 9), fillPaint(0xFFF2C14A));
  c.drawCircle(const Offset(-30, 0), 7, strokePaint(0xFFE0573E, 4));
}

void _coconutStall(Canvas c, int k) {
  _shadow(c, 80, 20);
  c.drawRect(const Rect.fromLTWH(-32, -22, 64, 26), fillPaint(0xFF9C7A50));
  c.drawRect(const Rect.fromLTWH(-32, -26, 64, 6), fillPaint(0xFFB79F6E));
  for (var i = 0; i < 4; i++) {
    c.drawCircle(Offset(-22 + i * 14.0, -30), 6, fillPaint(0xFF6E9C4E));
    c.drawCircle(Offset(-22 + i * 14.0, -32), 2, fillPaint(0xFFF4F1E6));
  }
  for (final x in [-30.0, 30.0]) {
    c.drawLine(Offset(x, -24), Offset(x, -66), strokePaint(0xFF7A5634, 3));
  }
  for (var i = 0; i < 6; i++) {
    c.drawRect(Rect.fromLTWH(-40 + i * 13.3, -72, 13.3, 12),
        fillPaint(i.isEven ? 0xFFE0573E : 0xFFF4F1E6));
  }
}

void _shells(Canvas c, int k) {
  for (var i = 0; i < 7; i++) {
    final q = Offset(
        (artNoise(k + i, 14) - .5) * 90, (artNoise(k + i, 15) - .5) * 40);
    final color = [0xFFF4DCCB, 0xFFE9B4A0, 0xFFF4F1E6, 0xFFD9C2E6][i % 4];
    c.drawPath(
        Path()
          ..moveTo(q.dx, q.dy + 4)
          ..lineTo(q.dx - 6, q.dy - 2)
          ..quadraticBezierTo(q.dx, q.dy - 9, q.dx + 6, q.dy - 2)
          ..close(),
        fillPaint(color));
    c.drawLine(q + const Offset(0, 4), q + const Offset(0, -5),
        strokePaint(0x55856B45, .8));
  }
  final star = Offset((artNoise(k, 16) - .5) * 60, 14);
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? 7.0 : 3.0;
    final q = star + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  c.drawPath(path..close(), fillPaint(0xFFE9824F));
}

// ------------------------------------------------------------------ rocky
void _shrubs(Canvas c, int k) {
  for (var i = 0; i < 5; i++) {
    final q = Offset(-36 + i * 18.0, (artNoise(k + i, 17) - .5) * 22);
    c.drawCircle(q + const Offset(3, 4), 13, fillPaint(0x2A3E4A2E));
    c.drawCircle(q, 12 + artNoise(k + i, 18) * 5,
        fillPaint(i.isEven ? 0xFF6F8C5A : 0xFF7E9A62));
    if ((k + i) % 3 == 0) {
      c.drawCircle(q + const Offset(-3, -4), 2.2, fillPaint(0xFFE9D27A));
    }
  }
}

void _cairn(Canvas c, int k) {
  _shadow(c, 44, 12);
  var y = 0.0;
  for (var i = 0; i < 5; i++) {
    final w = 30 - i * 5.0, h = 11 - i * 1.2;
    c.drawOval(
        Rect.fromCenter(
            center: Offset((i % 2) * 2.0 - 1, y - h / 2), width: w, height: h),
        fillPaint(i.isEven ? 0xFF9DA49A : 0xFF8A9590));
    y -= h - 1;
  }
}

void _wreck(Canvas c, int k) {
  _shadow(c, 130, 22);
  c.drawPath(
      Path()
        ..moveTo(-60, 0)
        ..quadraticBezierTo(-20, 18, 50, 4)
        ..lineTo(60, -20)
        ..quadraticBezierTo(0, -8, -54, -24)
        ..close(),
      fillPaint(0xFF5E4632));
  for (var i = 0; i < 6; i++) {
    final x = -44 + i * 18.0;
    c.drawLine(Offset(x, 4), Offset(x - 6, -34 - (i % 2) * 8.0),
        strokePaint(0xFF7A5E44, 4));
  }
  c.drawLine(
      const Offset(4, -10), const Offset(16, -64), strokePaint(0xFF6E5236, 5));
  c.drawLine(
      const Offset(0, -48), const Offset(28, -52), strokePaint(0xFF6E5236, 3));
  c.drawPath(
      Path()
        ..moveTo(16, -62)
        ..lineTo(36, -50)
        ..lineTo(18, -40)
        ..close(),
      fillPaint(0xAADCCFB0));
  c.drawOval(const Rect.fromLTWH(-50, -8, 22, 10), fillPaint(0xFF7FA266));
}

void _boulders(Canvas c, int k) {
  for (var i = 0; i < 3; i++) {
    final q = Offset(-24 + i * 22.0, (i % 2) * 8.0);
    final r = 18 - i * 4.0 + artNoise(k + i, 19) * 8;
    c.drawOval(
        Rect.fromCenter(
            center: q + const Offset(4, 5), width: r * 2.2, height: r * .9),
        fillPaint(0x2A3E4A2E));
    c.drawOval(
        Rect.fromCenter(
            center: q - Offset(0, r * .3), width: r * 2, height: r * 1.3),
        fillPaint(0xFF968B7A));
    c.drawOval(
        Rect.fromCenter(
            center: q - Offset(r * .3, r * .6), width: r, height: r * .45),
        fillPaint(0xFFBDB09A));
  }
}
