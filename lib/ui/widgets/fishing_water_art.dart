import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_art_kit.dart';

/// Water art. [paintWaterBody] is recorded into the cached chunks (depth,
/// sandy shallows, reefs); the rest is drawn live and limited to the view.

// Depth shading follows the open channel; the Sea Cave chamber has its own.
double _shadeTop(double x) =>
    2 * FishingRiver.bayCenter(x) - FishingRiver.bottom(x);
double _towardCenter(double x, double d) =>
    math.min(_shadeTop(x) + d, FishingRiver.bayCenter(x));
double _fromCenter(double x, double d) =>
    math.max(FishingRiver.bottom(x) - d, FishingRiver.bayCenter(x));

/// Water with depth: light turquoise shallows along both banks that deepen
/// toward the middle, sandy ripples on the bottom near shore and dark reef
/// patches in the open sea. [tint] shades a region (mangrove, rocky bay).
void paintWaterBody(Canvas c, double from, double to, {int? tint}) {
  final water = bankBand(from, to, FishingRiver.top, FishingRiver.bottom);
  c.drawPath(
      water,
      Paint()
        ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF478F98),
              Color(0xFF66B4B2),
              Color(0xFF91CDC0)
            ],
            stops: [
              0,
              .5,
              1
            ]).createShader(const Rect.fromLTRB(0, 200, 1, 1900)));
  c.drawPath(
      water,
      Paint()
        ..shader =
            const LinearGradient(colors: [Color(0x003C9FB9), Color(0xFF3C9FB9)])
                .createShader(const Rect.fromLTRB(FishingRiver.seaStart - 240,
                    0, FishingRiver.seaStart + 600, 1)));
  // Only the sea gets deep water; it fades in across the estuary.
  final deep = Paint()
    ..shader = const LinearGradient(colors: [
      Color(0x000A3A5A),
      Color(0x0E0A3A5A),
    ]).createShader(const Rect.fromLTRB(
        FishingRiver.seaStart - 500, 0, FishingRiver.seaStart + 300, 1));
  for (var i = 1; i <= 10; i++) {
    final d = 120.0 + i * 75;
    c.drawPath(
        bankBand(
            from, to, (x) => _towardCenter(x, d), (x) => _fromCenter(x, d)),
        deep);
  }
  // Clear shallows: stacked light bands give a soft gradient to the shore.
  for (var i = 1; i <= 10; i++) {
    final d = i * 15.0;
    c.drawPath(bankBand(from, to, _shadeTop, (x) => _towardCenter(x, d)),
        fillPaint(0x14A6EADD));
    c.drawPath(
        bankBand(from, to, (x) => _fromCenter(x, d), FishingRiver.bottom),
        fillPaint(0x14A6EADD));
  }
  // Sand ripples seen through the shallow water.
  final ripple = strokePaint(0x2EFFF3CF, 1.6);
  for (var x = (from / 24).floor() * 24.0; x < to; x += 24) {
    final k = x.toInt();
    for (final north in [true, false]) {
      final edge = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
      final y = edge + (north ? 1 : -1) * (8 + artNoise(k, north ? 1 : 2) * 30);
      c.drawPath(
          Path()
            ..moveTo(x - 7, y)
            ..quadraticBezierTo(x, y - 3, x + 7, y),
          ripple);
    }
  }
  // Reef shadows and coral speckles out in the open sea.
  for (var x = (from / 240).floor() * 240.0; x < to; x += 240) {
    for (var y = 0.0; y < FishingRiver.height; y += 240) {
      final k = x.toInt() * 31 + y.toInt();
      if (artNoise(k, 3) < .45) continue;
      final p = Offset(x + artNoise(k, 4) * 200, y + artNoise(k, 5) * 200);
      if (FishingRiver.coastBlend(p.dx) < .9 ||
          p.dy < FishingRiver.top(p.dx) + 260 ||
          p.dy > FishingRiver.bottom(p.dx) - 260 ||
          fishingSeaIsland.contains(p, inset: -160)) {
        continue;
      }
      for (var i = 0; i < 3; i++) {
        c.drawOval(
            Rect.fromCenter(
                center:
                    p + Offset(i * 34.0 - 34, (artNoise(k + i, 6) - .5) * 30),
                width: 70 + artNoise(k + i, 7) * 90,
                height: 34 + artNoise(k + i, 8) * 40),
            fillPaint(0x0D0B3B55));
      }
      if (artNoise(k, 9) < .5) {
        for (var i = 0; i < 6; i++) {
          c.drawCircle(
              p +
                  Offset((artNoise(k + i, 10) - .5) * 120,
                      (artNoise(k + i, 11) - .5) * 50),
              3 + artNoise(k + i, 12) * 4,
              fillPaint(i.isEven ? 0x2EF2A7A0 : 0x26FFE3A8));
        }
      }
    }
  }
  if (tint != null) c.drawPath(water, fillPaint(tint));
}

bool _inWater(Offset p, double margin) =>
    p.dy > FishingRiver.top(p.dx) + margin &&
    p.dy < FishingRiver.bottom(p.dx) - margin &&
    !fishingSeaIsland.contains(p, inset: -margin);

/// Brief twinkles of sunlight, and soft light patches drifting with the flow.
void paintWaterSparkles(Canvas c, double left, double right, double top,
    double bottom, double clock, double zoom) {
  final cell = zoom < .6 ? 120.0 : 64.0;
  final star = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 1.6;
  for (var col = (left / cell).floor(); col * cell < right; col++) {
    for (var row = (top / cell).floor(); row * cell < bottom; row++) {
      final k = col * 7919 + row * 104729;
      final p =
          Offset((col + artNoise(k, 1)) * cell, (row + artNoise(k, 2)) * cell);
      if (!_inWater(p, 14)) continue;
      final b =
          math.sin(clock * (.8 + artNoise(k, 3) * .9) + artNoise(k, 4) * 6.28);
      if (b < .8) continue;
      final tw = (b - .8) / .2;
      final r = 2 + tw * 4;
      star.color = Color.fromRGBO(255, 255, 245, tw * .85);
      c.drawLine(p - Offset(r, 0), p + Offset(r, 0), star);
      c.drawLine(p - Offset(0, r * .6), p + Offset(0, r * .6), star);
    }
  }
  // Soft streaks: they ride the current on the river and drift at sea.
  const streak = 150.0;
  for (var col = (left / streak).floor() - 1; col * streak < right; col++) {
    for (var row = (top / streak).floor(); row * streak < bottom; row++) {
      final k = col * 3571 + row * 811;
      final base = Offset(
          (col + artNoise(k, 5)) * streak, (row + artNoise(k, 6)) * streak);
      final sea = FishingRiver.coastBlend(base.dx);
      final flow = 9 * (1 - sea) + 2.5;
      final p =
          base + Offset((clock * flow + artNoise(k, 7) * streak) % streak, 0);
      if (!_inWater(p, 24)) continue;
      final a = (math.sin(clock * .7 + k) + 1) / 2;
      c.drawOval(Rect.fromCenter(center: p, width: 46 + sea * 30, height: 7),
          fillPaint(((10 + a * 22).round() << 24) | 0xFFFFFF));
    }
  }
}

/// Open-sea swells: crests rise, travel a little, break into foam and fade.
void paintSeaSwells(Canvas c, double left, double right, double top,
    double bottom, double clock) {
  const w = 260.0, h = 170.0;
  final crest = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (var col = (left / w).floor() - 1; col * w < right + w; col++) {
    for (var row = (top / h).floor() - 1; row * h < bottom + h; row++) {
      final k = col * 92821 + row * 6151;
      final sea = FishingRiver.coastBlend(col * w + w / 2) *
          (1 - FishingRiver.rockyBlend(col * w + w / 2) * .5);
      if (sea < .3) continue;
      final t = (clock * (.07 + artNoise(k, 1) * .05) + artNoise(k, 2)) % 1;
      final p = Offset((col + .15 + artNoise(k, 3) * .7) * w + t * 30,
          (row + .2 + artNoise(k, 4) * .6) * h + t * 26);
      if (!_inWater(p, 70)) continue;
      final life = math.sin(t * math.pi);
      final half = 22 + life * 46;
      final a = math.pow(life, 1.4) * .55 * sea;
      final rise = 6 + life * 5;
      crest
        ..strokeWidth = 4
        ..color = Color.fromRGBO(16, 70, 98, a * .35);
      c.drawPath(
          Path()
            ..moveTo(p.dx - half, p.dy + 4)
            ..quadraticBezierTo(p.dx, p.dy + 4 - rise, p.dx + half, p.dy + 4),
          crest);
      crest
        ..strokeWidth = 2.4
        ..color = Color.fromRGBO(240, 252, 250, a);
      c.drawPath(
          Path()
            ..moveTo(p.dx - half, p.dy)
            ..quadraticBezierTo(p.dx, p.dy - rise, p.dx + half, p.dy),
          crest);
      if (t > .62) {
        final foam = (t - .62) / .38;
        for (var i = 0; i < 6; i++) {
          final f = i / 5;
          c.drawCircle(
              Offset(p.dx - half + f * half * 2,
                  p.dy - rise * (1 - (2 * f - 1) * (2 * f - 1)) + foam * 6),
              1.6 + artNoise(k + i, 5) * 1.6,
              fillPaint(((a * (1 - foam) * 255).round() << 24) | 0xF4FBF8));
        }
      }
    }
  }
}

double _wash(double s, double clock) =>
    5 + 13 * (.5 + .5 * math.sin(clock * 1.15 - s / 70));

/// Waves running up the sandy sea shores and falling back.
void paintShoreWash(Canvas c, double left, double right, double clock) {
  double strength(double x) =>
      FishingRiver.coastBlend(x) *
      (1 - FishingRiver.rockyBlend(x)) *
      (1 - FishingRiver.mangroveBlend(x));
  for (final north in [true, false]) {
    final out = north ? -1.0 : 1.0;
    double edge(double x) =>
        north ? FishingRiver.top(x) : FishingRiver.bottom(x);
    Path? foam, wet, back;
    void flush() {
      if (foam == null) return;
      c.drawPath(wet!, strokePaint(0x26805F35, 10));
      c.drawPath(back!, strokePaint(0x66F4FBF8, 1.6));
      c.drawPath(foam!, strokePaint(0xD8F7FCF9, 3));
      foam = wet = back = null;
    }

    for (var x = (left / 10).floor() * 10.0; x <= right; x += 10) {
      if (strength(x) < .35 || FishingRiver.caveDepth(x) > 5) {
        flush();
        continue;
      }
      final w = _wash(x, clock);
      final f = Offset(x, edge(x) + out * w);
      final m = Offset(x, edge(x) + out * w * .45);
      final g = Offset(x, edge(x) + out * (w + 6));
      if (foam == null) {
        foam = Path()..moveTo(f.dx, f.dy);
        back = Path()..moveTo(m.dx, m.dy);
        wet = Path()..moveTo(g.dx, g.dy);
      } else {
        foam!.lineTo(f.dx, f.dy);
        back!.lineTo(m.dx, m.dy);
        wet!.lineTo(g.dx, g.dy);
      }
    }
    flush();
  }
}

/// The same wash around the island coast (drawn above the island art).
void paintIslandWash(Canvas c, double clock) {
  const island = fishingSeaIsland;
  final foam = Path(), back = Path(), wet = Path();
  for (var i = 0; i <= 140; i++) {
    final a = i * math.pi * 2 / 140;
    final r = island.radiusAt(a);
    final w = _wash(r * a, clock);
    final dir = Offset(math.cos(a), math.sin(a));
    final f = island.center + dir * (r - w);
    final m = island.center + dir * (r - w * .45);
    final g = island.center + dir * (r - w - 6);
    if (i == 0) {
      foam.moveTo(f.dx, f.dy);
      back.moveTo(m.dx, m.dy);
      wet.moveTo(g.dx, g.dy);
    } else {
      foam.lineTo(f.dx, f.dy);
      back.lineTo(m.dx, m.dy);
      wet.lineTo(g.dx, g.dy);
    }
  }
  c.drawPath(wet, strokePaint(0x26805F35, 10));
  c.drawPath(back, strokePaint(0x66F4FBF8, 1.6));
  c.drawPath(foam, strokePaint(0xD8F7FCF9, 3));
}
