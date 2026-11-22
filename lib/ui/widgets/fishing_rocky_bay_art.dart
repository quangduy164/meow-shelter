import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_props.dart';
import 'fishing_river_details.dart';
import 'fishing_art_kit.dart';
import 'fishing_rock_art.dart';

/// North shore life starts this far inland, clear of the cliff face.
const _cliffClear = 120.0;

/// Cliffs and cavern floor share the same bank boundaries as sailing and walking.
void paintRockyBay(Canvas c, double left, double right) {
  final from = math.max(left, FishingRiver.rockyBayStart - 300),
      to = math.min(right, FishingRiver.openSeaStart + 300);
  if (from >= to) return;
  c.saveLayer(Rect.fromLTRB(from, 0, to, FishingRiver.height), Paint());
  c.drawRect(Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()..color = const Color(0xFF9C9282));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) - 110,
          (x) => FishingRiver.bottom(x) + 125),
      Paint()..color = const Color(0xFFB5A88F));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) - 42,
          (x) => FishingRiver.bottom(x) + 48),
      Paint()..color = const Color(0xFFDCCCA8));
  c.drawPath(bankBand(from, to, FishingRiver.top, FishingRiver.bottom),
      Paint()..color = const Color(0xFF548D9B));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) + 24,
          (x) => FishingRiver.bottom(x) - 24),
      Paint()..color = const Color(0xFF3F7C90));
  // The cavern is a north-side inlet; the main bay remains an open route east.
  c.save();
  c.clipRect(const Rect.fromLTRB(FishingRiver.caveStart - 360, 0,
      FishingRiver.caveStart + 360, FishingRiver.height));
  c.clipPath(bankBand(
      math.max(from, FishingRiver.caveStart - 360),
      math.min(to, FishingRiver.caveStart + 360),
      (_) => 0,
      (x) => FishingRiver.bayTop(x) + 12));
  c.saveLayer(Rect.fromLTRB(from, 0, to, FishingRiver.height), Paint());
  c.drawRect(Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()..color = const Color(0xFF343F49));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) - 80,
          (x) => FishingRiver.bottom(x) + 90),
      Paint()..color = const Color(0xFF687471));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) - 30,
          (x) => FishingRiver.bottom(x) + 35),
      Paint()..color = const Color(0xFF929A89));
  c.drawPath(bankBand(from, to, FishingRiver.top, FishingRiver.bottom),
      Paint()..color = const Color(0xFF285F6B));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) + 18,
          (x) => FishingRiver.bottom(x) - 18),
      Paint()..color = const Color(0xFF245261));
  // An elliptical fade hugs the inlet so no straight seams show at its sides.
  final caveCenter = Offset(FishingRiver.caveStart,
      FishingRiver.bayTop(FishingRiver.caveStart) - 250);
  const stretch = 1.9;
  c.drawRect(
      Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.radial(
            caveCenter,
            330,
            const [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            const [0, .55, 1],
            TileMode.clamp,
            Float64List.fromList([
              1, 0, 0, 0, //
              0, stretch, 0, 0,
              0, 0, 1, 0,
              0, caveCenter.dy * (1 - stretch), 0, 1,
            ])));
  c.restore();
  c.restore();
  final rng = math.Random(721);
  for (var i = 0; i < 1500; i++) {
    final x = 6900 + rng.nextDouble() * 2100;
    if (x < from || x > to) continue;
    final north = i.isEven;
    final y = (north ? FishingRiver.top(x) : FishingRiver.bottom(x)) +
        (north ? -1 : 1) * (35 + rng.nextDouble() * 115);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x, y),
            width: 3 + rng.nextDouble() * 6,
            height: 2 + rng.nextDouble() * 3),
        Paint()
          ..color =
              i % 3 == 0 ? const Color(0x998E9B91) : const Color(0x997C8984));
  }
  paintCliffBand(c, from, to);
  // Sparse outcrops stand well back from the shore cliffs.
  for (var i = (from / 135).floor(); i * 135 < to + 135; i++) {
    for (final north in [true, false]) {
      final k = i * 2 + (north ? 1 : 0);
      if (artNoise(k, 0) > .4) continue;
      final x = i * 135.0 + 35 + (artNoise(k, 1) - .5) * 80;
      final point = Offset(
          x,
          (north ? FishingRiver.top(x) - 250 : FishingRiver.bottom(x) + 260) +
              (artNoise(k, 2) - .5) * 90);
      paintBoulder(c, point, 34 + artNoise(k, 5) * 22, k, inWater: false);
      if (artNoise(k, 3) < .5) {
        paintBoulder(c, point + Offset(artNoise(k, 4) * 60 + 30, 14),
            16 + artNoise(k, 6) * 10, k + 97,
            inWater: false);
      }
    }
  }
  _shoreLife(c, from, to);
  // A recognisable cleft marks the entrance without drawing a wall over the channel.
  if (from < 8350 && to > 7750) {
    for (final north in [true, false]) {
      const x = 8100.0;
      final p = Offset(
          x, north ? FishingRiver.top(x) - 35 : FishingRiver.bayTop(x) - 20);
      paintBoulder(c, p, 70, north ? 41 : 42, inWater: false);
      paintBoulder(c, p + const Offset(78, 18), 34, north ? 43 : 44,
          inWater: false);
    }
  }
  for (var i = (from / 95).floor(); i * 95 < to; i++) {
    final x = i * 95.0 + 18;
    if (FishingRiver.caveDepth(x) < 100) continue;
    final edge = FishingRiver.top(x);
    // Stalactites of varied width and length, some in twos or threes.
    for (var j = 0; j < 1 + (artNoise(i, 30) * 3).floor(); j++) {
      final sx = x + j * 22 - 10 + (artNoise(i + j, 31) - .5) * 20;
      final w = 8 + artNoise(i + j, 32) * 16;
      final tip = edge - 10 - artNoise(i + j, 33) * 55;
      c.drawPath(
          Path()
            ..moveTo(sx - w, edge - 95)
            ..quadraticBezierTo(sx - w * .3, (edge - 95 + tip) / 2, sx, tip)
            ..quadraticBezierTo(
                sx + w * .4, (edge - 95 + tip) / 2, sx + w, edge - 95)
            ..close(),
          Paint()
            ..color =
                j.isEven ? const Color(0xFF53635F) : const Color(0xFF4A5955));
      c.drawLine(
          Offset(sx - w * .4, edge - 88),
          Offset(sx - 1, tip + 8),
          Paint()
            ..color = const Color(0xFF81918A)
            ..strokeWidth = 1.6);
      c.drawCircle(
          Offset(sx, tip + 2), 1.8, Paint()..color = const Color(0xAA9AD6D0));
    }
  }
  // A shelf with a rope post and weathered boards gives a clear landing landmark.
  const x = 7710.0;
  if (x > from - 80 && x < to + 80) {
    final p = Offset(x, FishingRiver.bottom(x) + 12);
    for (var i = 0; i < 7; i++) {
      c.drawRect(
          Rect.fromLTWH(p.dx - 25, p.dy + i * 8, 50, 6),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFB1A484) : const Color(0xFF938C74));
    }
    c.drawLine(
        p + const Offset(34, 0),
        p + const Offset(34, 42),
        Paint()
          ..color = const Color(0xFF79765E)
          ..strokeWidth = 5);
    c.drawOval(
        Rect.fromCenter(center: p + const Offset(34, 12), width: 19, height: 8),
        Paint()
          ..color = const Color(0xFFD0C29A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
  for (var i = (from / 160).floor(); i * 160 < to; i++) {
    final x = i * 160.0 + 30;
    if (FishingRiver.caveDepth(x) < 100) continue;
    final p = Offset(x + (artNoise(i, 40) - .5) * 60,
        FishingRiver.top(x) - 30 - artNoise(i, 41) * 40);
    const tones = [
      (0xFF88B6AF, 0xFF64968E, 0x3388E0D0),
      (0xFFB49AE0, 0xFF8A70C0, 0x33B49AE0),
      (0xFFE7A1C4, 0xFFC07399, 0x33E7A1C4),
      (0xFF9FD3F0, 0xFF6EA8CC, 0x339FD3F0),
    ];
    final tone = tones[(artNoise(i, 42) * tones.length).floor()];
    final n = 3 + (artNoise(i, 43) * 4).floor();
    final size = .7 + artNoise(i, 44) * .8;
    c.drawOval(
        Rect.fromCenter(
            center: p + const Offset(18, -8),
            width: 90 * size,
            height: 50 * size),
        Paint()..color = Color(tone.$3));
    for (var j = 0; j < n; j++) {
      final bx = p.dx + j * 10 * size;
      final hgt = (16 + artNoise(i + j, 45) * 26) * size;
      final lean = (artNoise(i + j, 46) - .5) * 10;
      c.drawPath(
          Path()
            ..moveTo(bx, p.dy)
            ..lineTo(bx + 2 + lean, p.dy - hgt * .8)
            ..lineTo(bx + 5 * size + lean, p.dy - hgt)
            ..lineTo(bx + 9 * size + lean * .5, p.dy - hgt * .75)
            ..lineTo(bx + 10 * size, p.dy)
            ..close(),
          Paint()..color = Color(j.isEven ? tone.$1 : tone.$2));
      c.drawLine(
          Offset(bx + 3, p.dy - 2),
          Offset(bx + 4 + lean, p.dy - hgt * .7),
          Paint()
            ..color = const Color(0x88FFFFFF)
            ..strokeWidth = 1.2);
    }
  }
  _caveLife(c, from, to);
  _mask(c, from, to, FishingRiver.rockyBayStart - 300,
      FishingRiver.rockyBayStart + 300);
  c.drawRect(
      Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader =
            const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)])
                .createShader(const Rect.fromLTRB(
                    FishingRiver.openSeaStart - 300,
                    0,
                    FishingRiver.openSeaStart + 300,
                    FishingRiver.height)));
  c.restore();
  for (final rock in createRiverProps()) {
    if (rock.kind != RiverPropKind.rock ||
        rock.anchor.dx < from - 80 ||
        rock.anchor.dx > to + 80) {
      continue;
    }
    if (rock.radius >= 45 &&
        rock.anchor.dx > FishingRiver.rockyBayStart &&
        rock.anchor.dx < FishingRiver.openSeaStart) {
      _seaStack(c, rock.anchor, rock.radius, rock.anchor.dx.toInt());
    } else {
      paintRiverRock(c, rock.anchor, rock.radius);
    }
  }
}

void _mask(Canvas c, double from, double to, double start, double end) {
  c.drawRect(
      Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
                colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)])
            .createShader(Rect.fromLTRB(start, 0, end, FishingRiver.height)));
}

void _gull(Canvas c, Offset feet) {
  c.drawOval(
      Rect.fromCenter(center: feet + const Offset(0, -7), width: 16, height: 9),
      fillPaint(0xFFF4F4EE));
  c.drawOval(
      Rect.fromCenter(
          center: feet + const Offset(-2, -8), width: 10, height: 6),
      fillPaint(0xFF9AA3A6));
  c.drawCircle(feet + const Offset(7, -12), 4, fillPaint(0xFFF4F4EE));
  c.drawLine(
      feet + const Offset(10, -12),
      feet + const Offset(15, -11),
      Paint()
        ..color = const Color(0xFFE9B949)
        ..strokeWidth = 2);
  c.drawCircle(feet + const Offset(8, -13), 1, fillPaint(0xFF1F1A17));
}

/// Tide pools with starfish, seaweed, barnacled boulders and basking seals
/// along both bay shores.
void _shoreLife(Canvas c, double from, double to) {
  for (var i = (from / 85).floor(); i * 85 < to; i++) {
    if (i * 85.0 < FishingRiver.rockyBayStart - 150 ||
        i * 85.0 > FishingRiver.openSeaStart + 150) {
      continue;
    }
    final x = i * 85.0 + artNoise(i, 50) * 50;
    if (FishingRiver.caveDepth(x) > 40) continue;
    final north = i.isEven;
    final out = north ? -1.0 : 1.0;
    final edge = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
    // North life sits above the cliff rim, south life on the rock shelf.
    final p = Offset(
        x,
        edge +
            out *
                (north
                    ? _cliffClear + artNoise(i, 51) * 40
                    : 24 + artNoise(i, 51) * 34));
    final r = artNoise(i, 52);
    if (r < .3) {
      final pool = Rect.fromCenter(
          center: p,
          width: 40 + artNoise(i, 53) * 30,
          height: 18 + artNoise(i, 54) * 10);
      c.drawOval(pool.inflate(3), fillPaint(0xFF9DA49A));
      c.drawOval(pool, fillPaint(0xFF4E93A2));
      c.drawOval(pool.deflate(5).translate(-3, -2), fillPaint(0xFF68AEBB));
      _star(c, pool.center + Offset(pool.width * .2, 1),
          artNoise(i, 55) < .5 ? 0xFFE9824F : 0xFFD95C7A);
    } else if (r < .55) {
      for (var j = 0; j < 4; j++) {
        final base = p + Offset(j * 7 - 10, 0);
        c.drawPath(
            Path()
              ..moveTo(base.dx, base.dy)
              ..quadraticBezierTo(base.dx - 6 + j * 3, base.dy - 10,
                  base.dx + (j - 1.5) * 4, base.dy - 18 - (j % 2) * 6),
            Paint()
              ..color = Color(j.isEven ? 0xFF5E8C4C : 0xFF7E7A3E)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
      }
    } else if (r < .72) {
      final size = 10 + artNoise(i, 56) * 12;
      c.drawOval(
          Rect.fromCenter(center: p, width: size * 2.2, height: size * 1.3),
          fillPaint(0xFF8E9A94));
      for (var j = 0; j < 6; j++) {
        c.drawCircle(
            p +
                Offset((artNoise(i + j, 57) - .5) * size * 1.6,
                    (artNoise(i + j, 58) - .5) * size * .8),
            1.6,
            fillPaint(0xFFE6E1D0));
      }
    } else if (r < .8) {
      _seal(c, p, north);
    }
  }
}

void _star(Canvas c, Offset p, int color) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? 6.0 : 2.6;
    final q = p + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  c.drawPath(path..close(), fillPaint(color));
}

void _seal(Canvas c, Offset p, bool facingRight) {
  final d = facingRight ? 1.0 : -1.0;
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 6), width: 50, height: 10),
      fillPaint(0x33445150));
  c.drawPath(
      Path()
        ..moveTo(p.dx - d * 24, p.dy + 4)
        ..quadraticBezierTo(p.dx - d * 6, p.dy - 14, p.dx + d * 14, p.dy - 8)
        ..quadraticBezierTo(p.dx + d * 22, p.dy, p.dx + d * 8, p.dy + 5)
        ..close(),
      fillPaint(0xFF7E7F80));
  c.drawCircle(p + Offset(d * 17, -9), 7.5, fillPaint(0xFF8A8B8C));
  c.drawCircle(p + Offset(d * 20, -11), 1.4, fillPaint(0xFF1F1A17));
  c.drawCircle(p + Offset(d * 23, -8), 1.2, fillPaint(0xFF3A3A3A));
  c.drawPath(
      Path()
        ..moveTo(p.dx - d * 22, p.dy + 3)
        ..lineTo(p.dx - d * 30, p.dy - 2)
        ..lineTo(p.dx - d * 29, p.dy + 7)
        ..close(),
      fillPaint(0xFF6E6F70));
}

/// A tall rock pillar in open water, drawn on its collision footprint.
void _seaStack(Canvas c, Offset p, double r, int seed) {
  final h = r * (1.6 + artNoise(seed, 60) * .6);
  c.drawOval(
      Rect.fromCenter(
          center: p + const Offset(0, 6), width: r * 2.8, height: r * 1.1),
      fillPaint(0x55E9F6F4));
  c.drawOval(
      Rect.fromCenter(
          center: p + const Offset(6, 8), width: r * 2.3, height: r * .8),
      fillPaint(0x33304A50));
  double j(int k) => .82 + artNoise(seed + k, 64) * .36;
  final body = Path()
    ..moveTo(p.dx - r, p.dy)
    ..lineTo(p.dx - r * .9 * j(1), p.dy - h * .55 * j(2))
    ..lineTo(p.dx - r * .65 * j(3), p.dy - h * .9)
    ..lineTo(p.dx - r * .1 * j(4), p.dy - h)
    ..lineTo(p.dx + r * .55 * j(5), p.dy - h * .93 * j(6))
    ..lineTo(p.dx + r * .85 * j(7), p.dy - h * .5 * j(8))
    ..lineTo(p.dx + r, p.dy)
    ..close();
  c.drawPath(
      body, fillPaint(const [0xFF948A7C, 0xFF9C9384, 0xFF8B8378][seed % 3]));
  c.drawPath(
      Path()
        ..moveTo(p.dx + r * .1, p.dy - h)
        ..lineTo(p.dx + r * .55, p.dy - h * .93)
        ..lineTo(p.dx + r * .85, p.dy - h * .5)
        ..lineTo(p.dx + r, p.dy)
        ..lineTo(p.dx + r * .2, p.dy)
        ..close(),
      fillPaint(0xFF6A6258));
  c.drawPath(body, strokePaint(0xFF443E37, 2.4));
  c.save();
  c.clipPath(body);
  for (var i = 1; i < 5; i++) {
    final y = p.dy - h * i / 5;
    c.drawLine(
        Offset(p.dx - r, y),
        Offset(p.dx + r, y - 4),
        Paint()
          ..color = const Color(0x44C9D6CF)
          ..strokeWidth = 2);
  }
  c.drawRect(Rect.fromLTRB(p.dx - r, p.dy - 10, p.dx + r, p.dy),
      fillPaint(0x553B5B4E));
  c.restore();
  c.drawOval(
      Rect.fromCenter(
          center: Offset(p.dx - r * .05, p.dy - h * .95),
          width: r * 1.2,
          height: r * .4),
      fillPaint(0xFF7FA266));
  if (artNoise(seed, 61) < .6) _gull(c, Offset(p.dx + r * .2, p.dy - h * .97));
  if (artNoise(seed, 62) < .5) {
    _seal(c, Offset(p.dx - r * .2, p.dy + 2), artNoise(seed, 63) < .5);
  }
}

/// Stalagmites on the cave floor and roosting bats on the walls.
void _caveLife(Canvas c, double from, double to) {
  for (var i = (from / 55).floor(); i * 55 < to; i++) {
    final x = i * 55.0 + artNoise(i, 70) * 30;
    if (FishingRiver.caveDepth(x) < 80) continue;
    final edge = FishingRiver.top(x);
    final r = artNoise(i, 71);
    if (r < .5) {
      final base = Offset(x, edge - 18 - artNoise(i, 72) * 40);
      final hgt = 14 + artNoise(i, 73) * 30, w = 5 + artNoise(i, 74) * 7;
      c.drawPath(
          Path()
            ..moveTo(base.dx - w, base.dy)
            ..quadraticBezierTo(
                base.dx - w * .3, base.dy - hgt * .5, base.dx, base.dy - hgt)
            ..quadraticBezierTo(
                base.dx + w * .3, base.dy - hgt * .5, base.dx + w, base.dy)
            ..close(),
          fillPaint(0xFF6B7A74));
      c.drawLine(
          Offset(base.dx - w * .4, base.dy - 2),
          Offset(base.dx - 1, base.dy - hgt + 4),
          Paint()
            ..color = const Color(0x66B9C9C2)
            ..strokeWidth = 1.2);
    } else if (r < .7) {
      final b = Offset(x, edge - 60 - artNoise(i, 75) * 40);
      c.drawLine(
          b - const Offset(0, 6),
          b,
          Paint()
            ..color = const Color(0xFF2A2F35)
            ..strokeWidth = 1.2);
      c.drawOval(
          Rect.fromCenter(center: b + const Offset(0, 6), width: 8, height: 12),
          fillPaint(0xFF2A2F35));
      for (final d in [-1.0, 1.0]) {
        c.drawPath(
            Path()
              ..moveTo(b.dx, b.dy + 1)
              ..quadraticBezierTo(
                  b.dx + d * 7, b.dy + 4, b.dx + d * 4, b.dy + 13)
              ..lineTo(b.dx, b.dy + 10)
              ..close(),
            fillPaint(0xFF353B42));
      }
      c.drawCircle(b + const Offset(-1.5, 9), .9, fillPaint(0xFFE9D27A));
      c.drawCircle(b + const Offset(1.5, 9), .9, fillPaint(0xFFE9D27A));
    }
  }
}

/// Only visible water glints and cave light are animated; the HUD stays unaffected.
class FishingCaveLight extends CustomPainter {
  FishingCaveLight(this.round, Listenable frames) : super(repaint: frames);
  final FishingRiverRound round;
  @override
  void paint(Canvas c, Size size) {
    final left = round.cameraLeft, right = left + round.visibleWidth;
    if (right < FishingRiver.rockyBayStart - 200) return;
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(round.scale);
    c.translate(-left, -round.cameraTop);
    for (var i = (left / 150).floor(); i * 150 < right; i++) {
      final x = i * 150.0 + 50;
      if (x < FishingRiver.rockyBayStart) continue;
      final p = Offset(
          x,
          FishingRiver.center(x) +
              math.sin(i * 2.5) * FishingRiver.halfWidth(x) * .55);
      final t = (round.clock * .16 + i * .43) % 1;
      c.drawOval(
          Rect.fromCenter(center: p, width: 25 + t * 65, height: 5 + t * 12),
          Paint()
            ..color = Color.fromRGBO(149, 222, 210, (1 - t) * .2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    for (final x in [8000.0, 8200.0]) {
      if (x < left - 160 || x > right + 160) continue;
      final p = Offset(x, FishingRiver.top(x) + 65);
      final glow = Rect.fromCenter(center: p, width: 230, height: 230);
      c.drawOval(
          glow,
          Paint()
            ..shader = RadialGradient(colors: [
              Color.fromRGBO(
                  145, 223, 205, .13 + math.sin(round.clock * .8 + x) * .025),
              const Color(0x00A4E9CB)
            ]).createShader(glow));
      for (var i = 0; i < 7; i++) {
        final phase = round.clock * .7 + i * 2.4;
        c.drawCircle(
            p + Offset(math.sin(phase * .4) * 80, math.cos(phase * .5) * 65),
            1.5,
            Paint()
              ..color = Color.fromRGBO(
                  191, 240, 215, .18 + math.sin(phase).abs() * .35));
      }
    }
    for (var i = (left / 210).floor(); i * 210 < right; i++) {
      final x = i * 210.0 + 45;
      if (FishingRiver.caveDepth(x) < 100) continue;
      final t = (round.clock * .35 + i * .37) % 1;
      final start = FishingRiver.top(x) + 5;
      if (t < .6) {
        final y = start + t / .6 * 50;
        c.drawLine(
            Offset(x, y - 4),
            Offset(x, y),
            Paint()
              ..color = const Color(0x668BC6C2)
              ..strokeWidth = 1.5);
      } else {
        c.drawOval(
            Rect.fromCenter(
                center: Offset(x, start + 50),
                width: 6 + (t - .6) * 30,
                height: 3 + (t - .6) * 10),
            Paint()
              ..color = Color.fromRGBO(154, 223, 212, (1 - t) * .6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }
    // The world dims on entering; do not cover the screen-space buttons.
    final darkness =
        FishingRiver.caveBlend(round.cameraFocus.dx, y: round.cameraFocus.dy);
    if (darkness > 0) {
      final screen = Rect.fromLTWH(
          left, round.cameraTop, round.visibleWidth, round.visibleHeight);
      c.drawRect(
          screen, Paint()..color = Color.fromRGBO(10, 25, 36, .18 * darkness));
      c.drawRect(
          screen,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0x00091D29),
              Color.fromRGBO(7, 18, 27, .3 * darkness)
            ], stops: const [
              .35,
              1
            ]).createShader(screen));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(FishingCaveLight old) => old.round != round;
}
