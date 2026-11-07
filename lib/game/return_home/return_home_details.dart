import 'dart:math';

import 'package:flutter/painting.dart';

import 'return_home_road.dart';

/// Extra texture for the Return Home landscape: sky gradient, a horizon band
/// with each stretch's own far silhouettes, grass tufts and flowers, and a
/// surface pattern on the road. Everything is seeded and recorded once into
/// the cached background picture, so detail costs nothing per frame.

/// Picks a biome colour at world x, blended across stretch borders.
typedef BiomeTone = Color Function(
    double x, Color Function(ReturnHomeBiome biome) pick);

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

/// Vertical sky gradient: deeper at the top, hazy and light at the horizon.
void paintSkyGradient(
    Canvas canvas, ReturnHomeRoad road, double skyHeight, BiomeTone tone) {
  final w = road.worldWidth;
  const columns = 320;
  final dx = w / columns;
  for (var i = 0; i < columns; i++) {
    final x = i * dx;
    final sky = tone(x + dx / 2, (b) => b.sky);
    final rect = Rect.fromLTWH(x, 0, dx + 1, skyHeight + 1);
    canvas.drawRect(
        rect,
        Paint()
          ..isAntiAlias = false
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _mix(sky, const Color(0xFF3F7FB8), .22),
              sky,
              _mix(sky, const Color(0xFFFFF6E0), .45),
            ],
            stops: const [0, .55, 1],
          ).createShader(rect));
  }
}

/// Far scenery sitting on the horizon: two layers of soft hills tinted
/// toward the sky, topped with each stretch's landmark silhouettes.
void paintHorizon(
    Canvas canvas, ReturnHomeRoad road, double skyHeight, BiomeTone tone) {
  final w = road.worldWidth;
  final h = road.viewportHeight;
  const step = 24.0;
  for (final layer in [0, 1]) {
    final amp = h * (layer == 0 ? .045 : .03);
    final lift = layer == 0 ? h * .035 : h * .012;
    final haze = layer == 0 ? .55 : .32;
    for (var x = 0.0; x < w; x += step) {
      double top(double px) =>
          skyHeight -
          lift -
          amp * (.6 + .4 * sin(px / (layer == 0 ? 170 : 110) + layer * 2.1)) -
          amp * .35 * sin(px / 57 + layer);
      final color = _mix(tone(x, (b) => b.grass), tone(x, (b) => b.sky), haze);
      canvas.drawPath(
          Path()
            ..moveTo(x, top(x))
            ..lineTo(x + step + 1, top(x + step))
            ..lineTo(x + step + 1, skyHeight + 2)
            ..lineTo(x, skyHeight + 2)
            ..close(),
          Paint()..color = color);
    }
  }
  // Landmarks on the far ridge.
  final random = Random(17);
  for (var x = 30.0; x < w - 40; x += 46 + random.nextDouble() * 40) {
    final biome = road.biomeAt(x);
    final base = Offset(x, skyHeight - h * .03);
    final far = _mix(tone(x, (b) => b.grass), tone(x, (b) => b.sky), .42);
    final dark = _mix(far, const Color(0xFF1E3B2A), .18);
    switch (biome.scenery) {
      case ReturnHomeScenery.fence:
      case ReturnHomeScenery.garden:
      case ReturnHomeScenery.lane:
        _farTree(canvas, base, h * (.035 + random.nextDouble() * .02), dark);
      case ReturnHomeScenery.stream:
      case ReturnHomeScenery.bridge:
        if (random.nextDouble() < .45) {
          _farPeak(canvas, base, h * (.07 + random.nextDouble() * .04), far);
        } else {
          _farTree(canvas, base, h * .03, dark);
        }
      case ReturnHomeScenery.bamboo:
        for (var k = 0; k < 4; k++) {
          final p = base + Offset(k * 7.0, 0);
          final top = p - Offset(0, h * (.05 + random.nextDouble() * .03));
          canvas.drawLine(
              p,
              top,
              Paint()
                ..color = dark
                ..strokeWidth = 2.2
                ..strokeCap = StrokeCap.round);
          canvas.drawOval(
              Rect.fromCenter(
                  center: top + const Offset(4, 2), width: 10, height: 4),
              Paint()..color = dark);
        }
      case ReturnHomeScenery.field:
        if (random.nextDouble() < .3) {
          _farWindmill(canvas, base, h * .07, dark);
        } else {
          canvas.drawOval(Rect.fromCenter(center: base, width: 14, height: 8),
              Paint()..color = _mix(const Color(0xFFD8B256), far, .45));
        }
      case ReturnHomeScenery.village:
        _farRoofs(canvas, base, h, random, dark);
    }
  }
}

void _farTree(Canvas canvas, Offset base, double size, Color color) {
  final paint = Paint()..color = color;
  canvas.drawRect(
      Rect.fromLTWH(base.dx - 1, base.dy - size * .5, 2, size * .5), paint);
  canvas.drawCircle(base - Offset(0, size * .8), size * .45, paint);
  canvas.drawCircle(base - Offset(size * .3, size * .6), size * .32, paint);
  canvas.drawCircle(base - Offset(-size * .3, size * .6), size * .32, paint);
}

void _farPeak(Canvas canvas, Offset base, double height, Color color) {
  final peak = base - Offset(0, height);
  canvas.drawPath(
      Path()
        ..moveTo(base.dx - height * 1.1, base.dy + 2)
        ..lineTo(peak.dx, peak.dy)
        ..lineTo(base.dx + height * 1.2, base.dy + 2)
        ..close(),
      Paint()..color = _mix(color, const Color(0xFF6D7FA0), .3));
  // Snow cap.
  canvas.drawPath(
      Path()
        ..moveTo(peak.dx - height * .28, peak.dy + height * .25)
        ..lineTo(peak.dx, peak.dy)
        ..lineTo(peak.dx + height * .3, peak.dy + height * .26)
        ..lineTo(peak.dx + height * .1, peak.dy + height * .2)
        ..lineTo(peak.dx - height * .05, peak.dy + height * .28)
        ..close(),
      Paint()..color = const Color(0xDDFFFFFF));
}

void _farWindmill(Canvas canvas, Offset base, double height, Color color) {
  final paint = Paint()..color = color;
  canvas.drawPath(
      Path()
        ..moveTo(base.dx - 5, base.dy)
        ..lineTo(base.dx - 2.5, base.dy - height)
        ..lineTo(base.dx + 2.5, base.dy - height)
        ..lineTo(base.dx + 5, base.dy)
        ..close(),
      paint);
  final hub = base - Offset(0, height);
  final blade = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (var k = 0; k < 4; k++) {
    final a = k * pi / 2 + .4;
    canvas.drawLine(hub, hub + Offset(cos(a), sin(a)) * height * .55, blade);
  }
}

void _farRoofs(
    Canvas canvas, Offset base, double h, Random random, Color color) {
  final width = 18 + random.nextDouble() * 14;
  final wall = h * (.025 + random.nextDouble() * .015);
  final paint = Paint()..color = color;
  canvas.drawRect(
      Rect.fromLTWH(base.dx - width / 2, base.dy - wall, width, wall + 2),
      paint);
  canvas.drawPath(
      Path()
        ..moveTo(base.dx - width / 2 - 3, base.dy - wall)
        ..lineTo(base.dx, base.dy - wall - width * .45)
        ..lineTo(base.dx + width / 2 + 3, base.dy - wall)
        ..close(),
      paint);
  if (random.nextDouble() < .4) {
    canvas.drawRect(
        Rect.fromLTWH(base.dx + width * .18, base.dy - wall - width * .42, 3,
            width * .25),
        paint);
  }
}

/// Grass texture on both verges: soft light/dark patches, tufts, little
/// flowers and pebbles. Drawn before the road so the road covers stray marks.
void paintGrassDetail(
    Canvas canvas, ReturnHomeRoad road, double skyHeight, BiomeTone tone) {
  final w = road.worldWidth;
  final h = road.viewportHeight;
  final random = Random(29);
  // Shade toward the bottom of the screen for depth.
  canvas.drawRect(
      Rect.fromLTWH(0, skyHeight, w, h - skyHeight),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x18FFFFFF), Color(0x00000000), Color(0x22203010)],
          stops: [0, .45, 1],
        ).createShader(Rect.fromLTWH(0, skyHeight, w, h - skyHeight)));
  for (var x = 8.0; x < w; x += 14 + random.nextDouble() * 10) {
    final grass = tone(x, (b) => b.grass);
    final dark = _mix(grass, const Color(0xFF1F3A1A), .28);
    final light = _mix(grass, const Color(0xFFFFFFE0), .28);
    final scenery = road.biomeAt(x).scenery;
    for (final side in [-1.0, 1.0]) {
      final edge = side < 0 ? road.topEdge(x) - 8 : road.bottomEdge(x) + 8;
      final far = side < 0 ? skyHeight + 4 : h - 4;
      if ((side < 0 ? edge - far : far - edge) < 6) continue;
      final y = edge + (far - edge) * random.nextDouble();
      final p = Offset(x + random.nextDouble() * 8, y);
      final roll = random.nextDouble();
      if (roll < .12) {
        canvas.drawOval(
            Rect.fromCenter(
                center: p,
                width: 26 + random.nextDouble() * 30,
                height: 7 + random.nextDouble() * 5),
            Paint()
              ..color = (random.nextBool() ? dark : light).withOpacity(.35));
      } else if (roll < .78) {
        _tuft(
            canvas,
            p,
            5 + random.nextDouble() * 5,
            scenery == ReturnHomeScenery.field
                ? _mix(dark, const Color(0xFFB8952E), .5)
                : dark);
      } else if (roll < .92) {
        const petals = [
          Color(0xFFFFF4DA),
          Color(0xFFFFC1C7),
          Color(0xFFFFE07A),
          Color(0xFFC9B6F0),
        ];
        final petal = petals[random.nextInt(petals.length)];
        for (var k = 0; k < 4; k++) {
          final a = k * pi / 2;
          canvas.drawCircle(
              p + Offset(cos(a), sin(a)) * 2.2, 1.8, Paint()..color = petal);
        }
        canvas.drawCircle(p, 1.3, Paint()..color = const Color(0xFFE8A93A));
      } else {
        canvas.drawOval(Rect.fromCenter(center: p, width: 6, height: 4),
            Paint()..color = const Color(0xFFB9B2A0));
        canvas.drawOval(
            Rect.fromCenter(
                center: p - const Offset(.8, .8), width: 3, height: 1.6),
            Paint()..color = const Color(0x88FFFFFF));
      }
    }
  }
}

void _tuft(Canvas canvas, Offset p, double size, Color color) {
  final blade = Paint()
    ..color = color
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(p, p + Offset(-size * .45, -size * .8), blade);
  canvas.drawLine(p, p + Offset(0, -size), blade);
  canvas.drawLine(p, p + Offset(size * .45, -size * .75), blade);
}

/// Surface pattern on the lane, chosen per stretch: pebbles and wheel ruts on
/// dirt, cobbles in the village, flat paving slabs on the lane home.
void paintRoadDetail(Canvas canvas, ReturnHomeRoad road, BiomeTone tone) {
  final w = road.worldWidth;
  final random = Random(41);
  for (var x = 20.0; x < w - 20; x += 9) {
    final biome = road.biomeAt(x);
    final c = road.centerY(x);
    final half = road.halfWidth(x);
    final roadColor = tone(x, (b) => b.road);
    final dark = _mix(roadColor, const Color(0xFF3A2414), .22);
    final light = _mix(roadColor, const Color(0xFFFFFFFF), .3);
    switch (biome.scenery) {
      case ReturnHomeScenery.bridge:
        // Planks are painted with the bridge props.
        break;
      case ReturnHomeScenery.village:
        // Cobbles: staggered rounded stones across the street.
        if ((x / 9).round() % 2 == 0) {
          final rows = (half * 2 / 13).floor();
          for (var r = 0; r < rows; r++) {
            final y = c - half + 7 + r * 13;
            final ox = (r.isOdd ? 4.5 : 0) + random.nextDouble() * 1.5;
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromCenter(
                        center: Offset(x + ox, y), width: 14, height: 10),
                    const Radius.circular(4)),
                Paint()..color = dark.withOpacity(.22));
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromCenter(
                        center: Offset(x + ox - 1, y - 1),
                        width: 11,
                        height: 7),
                    const Radius.circular(3)),
                Paint()..color = light.withOpacity(.18));
          }
        }
      case ReturnHomeScenery.lane:
        // Paving slabs with thin joints every few steps.
        if ((x / 9).round() % 5 == 0) {
          canvas.drawLine(
              Offset(x, c - half * .9),
              Offset(x, c + half * .9),
              Paint()
                ..color = dark.withOpacity(.25)
                ..strokeWidth = 1.5);
        }
        canvas.drawLine(
            Offset(x, c),
            Offset(x + 9, road.centerY(x + 9)),
            Paint()
              ..color = dark.withOpacity(.12)
              ..strokeWidth = 1.2);
      default:
        // Dirt: two soft wheel ruts and scattered pebbles.
        for (final rut in [-.45, .45]) {
          canvas.drawLine(
              Offset(x, c + half * rut),
              Offset(x + 9, road.centerY(x + 9) + road.halfWidth(x + 9) * rut),
              Paint()
                ..color = dark.withOpacity(.13)
                ..strokeWidth = 5
                ..strokeCap = StrokeCap.round);
        }
        if (random.nextDouble() < .55) {
          final p = Offset(x + random.nextDouble() * 9,
              c + (random.nextDouble() * 2 - 1) * half * .85);
          final r = 1.2 + random.nextDouble() * 1.8;
          canvas.drawCircle(p, r, Paint()..color = dark.withOpacity(.45));
          canvas.drawCircle(p - Offset(r * .3, r * .3), r * .45,
              Paint()..color = light.withOpacity(.6));
        }
    }
  }
}
