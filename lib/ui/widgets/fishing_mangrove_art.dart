import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_props.dart';
import 'fishing_art_kit.dart';

/// Recorded into the existing chunk cache; shared channel bounds define mud/water.
void paintMangrove(Canvas c, double left, double right) {
  final from = math.max(left, FishingRiver.mangroveStart - 300),
      to = math.min(right, FishingRiver.seaStart + 300);
  if (from >= to) return;
  c.save();
  // Fade the new ground into the estuary, without a hard vertical biome seam.
  c.saveLayer(Rect.fromLTRB(from, 0, to, FishingRiver.height), Paint());
  c.drawRect(Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()..color = const Color(0xFF82977A));
  final wet = bankBand(from, to, (x) => FishingRiver.top(x) - 60,
      (x) => FishingRiver.bottom(x) + 70);
  c.drawPath(wet, Paint()..color = const Color(0xFF8C8A65));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) - 25,
          (x) => FishingRiver.bottom(x) + 25),
      Paint()..color = const Color(0xFF737C60));
  c.drawPath(bankBand(from, to, FishingRiver.top, FishingRiver.bottom),
      Paint()..color = const Color(0xFF568D80));
  c.drawPath(
      bankBand(from, to, (x) => FishingRiver.top(x) + 18,
          (x) => FishingRiver.bottom(x) - 18),
      Paint()..color = const Color(0xFF4F827B));
  final rng = math.Random(851);
  for (var i = 0; i < 1800; i++) {
    final x = 3300 + rng.nextDouble() * 2100;
    if (x < from || x > to) continue;
    final north = i.isEven;
    final bank = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
    final y = bank + (north ? -1 : 1) * (25 + rng.nextDouble() * 210);
    final p = Offset(x, y);
    if (i % 5 == 0) {
      c.drawOval(Rect.fromCenter(center: p, width: 8, height: 4),
          Paint()..color = const Color(0x665C6D58));
    } else {
      c.drawLine(
          p,
          p - Offset(rng.nextDouble() * 2, 5 + rng.nextDouble() * 9),
          Paint()
            ..color = const Color(0xFF737451)
            ..strokeWidth = 1.7
            ..strokeCap = StrokeCap.round);
    }
  }
  // Background groves: mixed species, sizes, offsets and mirroring so the
  // forest never reads as a stamped row.
  for (var i = (from / 100).floor(); i * 100 < to + 100; i++) {
    for (final north in [true, false]) {
      final k = i * 2 + (north ? 0 : 1);
      final x = i * 100.0 + 35 + (artNoise(k, 1) - .5) * 70;
      final y =
          (north ? FishingRiver.top(x) - 150 : FishingRiver.bottom(x) + 215) +
              (artNoise(k, 2) - .5) * 80;
      final r = artNoise(k, 3);
      final kind = r < .38
          ? _Mangrove.tall
          : r < .62
              ? _Mangrove.bush
              : r < .78
                  ? _Mangrove.nipa
                  : r < .88
                      ? _Mangrove.snag
                      : _Mangrove.sapling;
      _place(c, Offset(x, y), kind, k, .72 + artNoise(k, 4) * .4);
    }
  }
  _mudLife(c, from, to);
  // Foremost trees sit on the same root footprints used by collision.
  for (final root in createRiverProps()
      .where((p) => p.kind == RiverPropKind.mangroveRoot)) {
    if (root.anchor.dx < from - 100 || root.anchor.dx > to + 100) continue;
    final k = root.anchor.dx.toInt() + root.anchor.dy.toInt();
    _place(
        c,
        root.anchor,
        artNoise(k, 5) < .7 ? _Mangrove.tall : _Mangrove.bush,
        k,
        .9 + artNoise(k, 6) * .28);
  } // Tiny mud pools and crab holes add detail along the walkable shore.
  for (var i = (from / 190).floor(); i * 190 < to; i++) {
    final x = i * 190.0 + 45;
    final p = Offset(x, FishingRiver.bottom(x) + 90);
    c.drawOval(Rect.fromCenter(center: p, width: 36, height: 13),
        Paint()..color = const Color(0xFF6A8774));
    c.drawOval(
        Rect.fromCenter(center: p + const Offset(33, -8), width: 7, height: 4),
        Paint()..color = const Color(0xFF525E48));
  }
  const dockX = 4620.0;
  if (dockX > from - 80 && dockX < to + 80) {
    final base = Offset(dockX, FishingRiver.bottom(dockX) + 12);
    for (var i = 0; i < 8; i++) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(base.dx - 22, base.dy + i * 7, 44, 5),
              const Radius.circular(1)),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFAD976D) : const Color(0xFF96845F));
    }
    for (final side in [-1.0, 1.0]) {
      c.drawLine(
          base + Offset(side * 25, -10),
          base + Offset(side * 25, 59),
          Paint()
            ..color = const Color(0xFF75674D)
            ..strokeWidth = 4);
    }
  }
  c.drawRect(
      Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader =
            const LinearGradient(colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)])
                .createShader(const Rect.fromLTRB(
                    FishingRiver.mangroveStart - 300,
                    0,
                    FishingRiver.mangroveStart + 300,
                    FishingRiver.height)));
  c.drawRect(
      Rect.fromLTRB(from, 0, to, FishingRiver.height),
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader =
            const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)])
                .createShader(const Rect.fromLTRB(FishingRiver.seaStart - 300,
                    0, FishingRiver.seaStart + 300, FishingRiver.height)));
  c.restore();
  c.restore();
}

enum _Mangrove { tall, bush, nipa, snag, sapling }

void _place(Canvas c, Offset p, _Mangrove kind, int seed, double scale) {
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(artNoise(seed, 7) < .5 ? -scale : scale, scale);
  switch (kind) {
    case _Mangrove.tall:
      _tall(c, seed);
    case _Mangrove.bush:
      _bush(c, seed);
    case _Mangrove.nipa:
      _nipa(c, seed);
    case _Mangrove.snag:
      _snag(c, seed);
    case _Mangrove.sapling:
      _sapling(c, seed);
  }
  c.restore();
}

const _leafTones = [0xFF62835A, 0xFF739563, 0xFF527B54, 0xFF5C8A4E, 0xFF7B9A5C];

void _stiltRoots(Canvas c, int count, double spread, double top) {
  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < count; i++) {
      final path = Path()
        ..moveTo(side * 5, top)
        ..quadraticBezierTo(side * (spread * .7 + i * 6), top * .3,
            side * (spread + i * 10), 8 + i * 5.0);
      c.drawPath(path, strokePaint(0xFF6C6246, 6 - i * 1.0));
      c.drawPath(
          path.shift(const Offset(-1, -1)), strokePaint(0xFFAA9670, 1.3));
    }
  }
}

void _canopy(Canvas c, int seed, Offset center, double rx, double ry, int blobs,
    double blob) {
  for (var i = 0; i < blobs; i++) {
    final a = i * 2.4 + artNoise(seed, 10) * 6;
    final q = center +
        Offset(math.cos(a) * rx * (.45 + artNoise(seed + i, 11) * .55),
            math.sin(a) * ry * (.45 + artNoise(seed + i, 12) * .55));
    final w = blob * (.8 + artNoise(seed + i, 13) * .45);
    c.drawOval(
        Rect.fromCenter(
            center: q + const Offset(1, 7), width: w * 1.07, height: w * .65),
        fillPaint(0xFF426C51));
    c.drawOval(Rect.fromCenter(center: q, width: w, height: w * .6),
        fillPaint(_leafTones[(i + seed) % _leafTones.length]));
  }
}

void _tall(Canvas c, int seed) {
  c.drawOval(const Rect.fromLTWH(-49, -10, 98, 27), fillPaint(0x3351644A));
  _stiltRoots(c, 3, 25, -44);
  final lean = (artNoise(seed, 8) - .5) * 18;
  c.drawPath(
      Path()
        ..moveTo(-7, -35)
        ..quadraticBezierTo(6 + lean, -70, -5 + lean, -103),
      strokePaint(0xFF81734F, 14));
  c.drawLine(const Offset(-2, -67), Offset(28 + lean, -105),
      strokePaint(0xFF81734F, 7));
  _canopy(c, seed, Offset(lean, -108), 40, 24, 6 + seed % 3, 60);
  // Hanging propagules.
  for (var i = 0; i < 4 + seed % 3; i++) {
    c.drawOval(
        Rect.fromCenter(
            center: Offset(-33 + i * 15.0 + lean, -92 + i % 2 * 9),
            width: 5,
            height: 16),
        fillPaint(0xFF94A568));
  }
}

void _bush(Canvas c, int seed) {
  c.drawOval(const Rect.fromLTWH(-58, -8, 116, 24), fillPaint(0x3351644A));
  _stiltRoots(c, 2, 30, -26);
  c.drawLine(
      const Offset(0, -24), const Offset(0, -48), strokePaint(0xFF81734F, 10));
  _canopy(c, seed, const Offset(0, -58), 52, 16, 7 + seed % 3, 52);
  // Small white flowers.
  for (var i = 0; i < 5; i++) {
    c.drawCircle(Offset(-40 + i * 20.0, -60 + math.sin(i * 1.7 + seed) * 10),
        2.4, fillPaint(0xFFF3EFD2));
  }
}

void _nipa(Canvas c, int seed) {
  c.drawOval(const Rect.fromLTWH(-40, -6, 80, 18), fillPaint(0x334C6A55));
  for (var i = 0; i < 7; i++) {
    final a = -math.pi / 2 + (i - 3) * .42 + (artNoise(seed + i, 14) - .5) * .2;
    final len = 62 + artNoise(seed + i, 15) * 28;
    final tip = Offset(math.cos(a) * len, math.sin(a) * len * .9);
    final mid = tip * .55 + Offset(math.cos(a + .6) * 6, -8);
    final frond = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy);
    c.drawPath(frond, strokePaint(0xFF5E7F45, 3));
    for (var j = 1; j < 7; j++) {
      final t = j / 7;
      final q = Offset.lerp(Offset.zero, tip, t)! +
          Offset(0, -math.sin(t * math.pi) * 6);
      for (final side in [-1.0, 1.0]) {
        c.drawLine(
            q,
            q +
                Offset(math.cos(a + side * 1.2) * 13 * (1 - t * .5),
                    math.sin(a + side * 1.2) * 11 * (1 - t * .5)),
            strokePaint(j.isEven ? 0xFF7FA35B : 0xFF6A9150, 3));
      }
    }
  }
  c.drawOval(const Rect.fromLTWH(-8, -10, 16, 12), fillPaint(0xFF7A5634));
}

void _snag(Canvas c, int seed) {
  c.drawOval(const Rect.fromLTWH(-40, -8, 80, 22), fillPaint(0x3351644A));
  for (final side in [-1.0, 1.0]) {
    for (var i = 0; i < 2; i++) {
      c.drawPath(
          Path()
            ..moveTo(side * 4, -30)
            ..quadraticBezierTo(
                side * (16 + i * 6), -8, side * (22 + i * 9), 6 + i * 4.0),
          strokePaint(0xFF8B8270, 5 - i * 1.0));
    }
  }
  final bark = strokePaint(0xFFA59B86, 9);
  c.drawLine(const Offset(0, -26), const Offset(4, -92), bark);
  c.drawLine(
      const Offset(2, -60), const Offset(-24, -84), bark..strokeWidth = 5);
  c.drawLine(
      const Offset(4, -78), const Offset(26, -98), bark..strokeWidth = 4);
  c.drawLine(
      const Offset(-24, -84), const Offset(-30, -96), bark..strokeWidth = 3);
  if (artNoise(seed, 16) < .6) _egret(c, const Offset(24, -98), .7);
}

void _sapling(Canvas c, int seed) {
  c.drawOval(const Rect.fromLTWH(-20, -4, 40, 12), fillPaint(0x3351644A));
  _stiltRoots(c, 1, 12, -16);
  c.drawLine(
      const Offset(0, -14), const Offset(1, -32), strokePaint(0xFF81734F, 4));
  _canopy(c, seed, const Offset(1, -36), 12, 7, 3, 22);
}

/// White egret, standing; [p] is the feet.
void _egret(Canvas c, Offset p, double s) {
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(s);
  c.drawLine(
      const Offset(-2, 0), const Offset(-1, -14), strokePaint(0xFF3E3A33, 1.6));
  c.drawLine(
      const Offset(3, 0), const Offset(2, -14), strokePaint(0xFF3E3A33, 1.6));
  c.drawOval(const Rect.fromLTWH(-12, -28, 24, 15), fillPaint(0xFFF7F5EC));
  c.drawPath(
      Path()
        ..moveTo(6, -24)
        ..quadraticBezierTo(14, -34, 9, -42)
        ..quadraticBezierTo(6, -48, 12, -50),
      strokePaint(0xFFF7F5EC, 4));
  c.drawCircle(const Offset(12, -50), 4, fillPaint(0xFFF7F5EC));
  c.drawLine(
      const Offset(15, -50), const Offset(25, -48), strokePaint(0xFFE9B949, 2));
  c.drawCircle(const Offset(13, -51), 1, fillPaint(0xFF1F1A17));
  c.restore();
}

/// Breathing roots, crabs, mudskippers, egrets and fallen logs on the mud.
void _mudLife(Canvas c, double from, double to) {
  for (var i = (from / 70).floor(); i * 70 < to; i++) {
    final x = i * 70.0 + artNoise(i, 20) * 40;
    final north = i.isEven;
    final edge = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
    final out = north ? -1.0 : 1.0;
    final p = Offset(x, edge + out * (14 + artNoise(i, 21) * 40));
    final r = artNoise(i, 22);
    if (r < .45) {
      // Pneumatophores: a cluster of pencil roots poking from the mud.
      for (var j = 0; j < 5 + i % 4; j++) {
        final q = p +
            Offset((artNoise(i + j, 23) - .5) * 34,
                (artNoise(i + j, 24) - .5) * 14);
        c.drawLine(q, q - Offset(0, 6 + artNoise(i + j, 25) * 8),
            strokePaint(0xFF7E6E4E, 2.4));
      }
    } else if (r < .6) {
      _crab(c, p, i);
    } else if (r < .72) {
      _mudskipper(c, p, north);
    } else if (r < .78) {
      _egret(c, p + Offset(0, out * 10), .85);
    } else if (r < .84) {
      c.save();
      c.translate(p.dx, p.dy + out * 20);
      c.rotate((artNoise(i, 26) - .5) * .8);
      c.drawLine(const Offset(-30, 0), const Offset(30, 0),
          strokePaint(0xFF6E5C40, 11));
      c.drawLine(const Offset(-26, -2), const Offset(26, -2),
          strokePaint(0xFF9C8661, 2));
      c.drawLine(const Offset(10, 0), const Offset(22, -14),
          strokePaint(0xFF6E5C40, 5));
      c.drawOval(const Rect.fromLTWH(26, -5, 9, 10), fillPaint(0xFFB9A57A));
      c.restore();
    }
  }
}

void _crab(Canvas c, Offset p, int seed) {
  final red = seed.isEven ? 0xFFC4553E : 0xFFD9733B;
  for (final side in [-1.0, 1.0]) {
    for (var j = 0; j < 3; j++) {
      c.drawLine(p + Offset(side * 4, j * 2.0 - 1),
          p + Offset(side * 10, j * 3.0 + 2), strokePaint(red, 1.4));
    }
    c.drawCircle(p + Offset(side * 9, -5), 3, fillPaint(red));
  }
  c.drawOval(Rect.fromCenter(center: p, width: 13, height: 9), fillPaint(red));
  c.drawCircle(p + const Offset(-2.5, -4), 1.3, fillPaint(0xFF1F1A17));
  c.drawCircle(p + const Offset(2.5, -4), 1.3, fillPaint(0xFF1F1A17));
}

void _mudskipper(Canvas c, Offset p, bool facingRight) {
  final d = facingRight ? 1.0 : -1.0;
  c.drawOval(
      Rect.fromCenter(center: p, width: 22, height: 8), fillPaint(0xFF7D7458));
  c.drawPath(
      Path()
        ..moveTo(p.dx - d * 10, p.dy)
        ..lineTo(p.dx - d * 17, p.dy - 5)
        ..lineTo(p.dx - d * 17, p.dy + 5)
        ..close(),
      fillPaint(0xFF6A6249));
  c.drawCircle(p + Offset(d * 7, -4), 2.6, fillPaint(0xFFE8E0C4));
  c.drawCircle(p + Offset(d * 7.5, -4), 1.2, fillPaint(0xFF1F1A17));
  c.drawLine(
      p + Offset(d * 2, 3), p + Offset(d * 6, 7), strokePaint(0xFF6A6249, 2));
}
