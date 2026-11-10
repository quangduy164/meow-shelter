import 'dart:math';

import 'package:flutter/painting.dart';

import '../world/nature_art.dart';
import 'return_home_road.dart';

/// Roadside art, one painter per [ReturnHomeScenery]. Everything here derives
/// its position from the road, so props follow the curve for free.
///
/// To add a biome: give it a scenery value, append a [ReturnHomeBiome] entry and
/// add one painter plus one case in [paintSceneryProp].

/// Spacing between props, and how far short of the house they stop.
const double sceneryStep = 112.0;
const double sceneryEndMargin = 300.0;

/// The stream hugs the lane for the whole stretch and pinches out at both ends,
/// so it arrives and leaves instead of being sawn off at a border.
const double streamShoulder = 130.0;

void paintSceneryProp(
  Canvas canvas,
  ReturnHomeRoad road,
  ReturnHomeScenery scenery,
  double x,
  int index,
) {
  switch (scenery) {
    case ReturnHomeScenery.fence:
      paintWoodFence(canvas, road, x, x + sceneryStep);
    case ReturnHomeScenery.garden:
      paintGardenProp(canvas, road, x, index);
    case ReturnHomeScenery.bamboo:
      paintBamboo(canvas, road, x, index);
    case ReturnHomeScenery.stream:
      paintStreamReeds(canvas, road, x);
    case ReturnHomeScenery.bridge:
      paintBridgeSpan(canvas, road, x, x + sceneryStep);
    case ReturnHomeScenery.field:
      paintFieldProp(canvas, road, x, index);
    case ReturnHomeScenery.village:
      paintVillageProp(canvas, road, x, index);
    case ReturnHomeScenery.lane:
      paintLaneProp(canvas, road, x, index);
  }
}

void paintWoodFence(Canvas canvas, ReturnHomeRoad road, double x0, double x1) {
  final a = road.edgePoint(x0, -1);
  final b = road.edgePoint(x1, -1);
  final rail = Paint()
    ..color = const Color(0xFFC9A274)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(a - const Offset(0, 11), b - const Offset(0, 11), rail);
  canvas.drawLine(a - const Offset(0, 25), b - const Offset(0, 25), rail);
  canvas.drawLine(
      a + const Offset(0, 6),
      a - const Offset(0, 34),
      Paint()
        ..color = const Color(0xFF9A7550)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
}

void paintGardenProp(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  final h = road.viewportHeight;
  if (index % 3 == 0) {
    final base = road.edgePoint(x, -1) + const Offset(0, -6);
    paintLeafyTree(canvas, base, h * .12 + 62, seed: index);
    return;
  }
  final side = index.isEven ? -1.0 : 1.0;
  final base = road.edgePoint(x, side) + Offset(0, side * 14);
  final leaves = Paint()..color = const Color(0xFF5FA355);
  canvas.drawCircle(base, 13, leaves);
  canvas.drawCircle(base + const Offset(12, 3), 9, leaves);
  canvas.drawCircle(base - const Offset(11, 2), 8, leaves);
  final bloom = road.edgePoint(x + 46, -side) + Offset(0, -side * 9);
  canvas.drawCircle(bloom, 4, Paint()..color = const Color(0xFFFFC1C7));
  canvas.drawCircle(
      bloom + const Offset(5, 2), 3, Paint()..color = const Color(0xFFFFE49A));
}

void paintStream(Canvas canvas, ReturnHomeRoad road) {
  final biomes = road.biomes;
  final biome = biomes.firstWhere((b) => b.scenery == ReturnHomeScenery.stream);
  final nextFrom = biomes.indexWhere((b) => b.from > biome.from);
  final w = road.worldWidth;
  final h = road.viewportHeight;
  final x0 = max(0.0, biome.from * w - streamShoulder);
  final x1 = min(
      w, (nextFrom == -1 ? 1.0 : biomes[nextFrom].from) * w + streamShoulder);
  const steps = 26;
  final dx = (x1 - x0) / steps;
  final shore = <Offset>[];
  final edge = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final x = x0 + i * dx;
    final y = road.bottomEdge(x) + 12;
    final pinch = min(1.0, min(x - x0, x1 - x) / streamShoulder);
    shore.add(Offset(x, y));
    edge.add(Offset(x, y + h * .1 * pinch));
  }
  final path = Path()..moveTo(shore.first.dx, shore.first.dy);
  for (final p in shore.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  for (final p in edge.reversed) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  canvas.drawPath(path, Paint()..color = const Color(0xFF6FB6CE));
}

void paintStreamReeds(Canvas canvas, ReturnHomeRoad road, double x) {
  final shore =
      road.edgePoint(x, 1) + Offset(0, 12 + road.viewportHeight * .05);
  final reed = Paint()
    ..color = const Color(0xFF3F7F63)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  for (var k = -1; k <= 1; k++) {
    canvas.drawLine(
        shore + Offset(k * 5.0, 11), shore + Offset(k * 10.0, -12), reed);
  }
  final ripple = Paint()
    ..color = const Color(0x66FFFFFF)
    ..strokeWidth = 2;
  canvas.drawLine(
      shore - const Offset(16, 6), shore - const Offset(2, 6), ripple);
  canvas.drawCircle(road.edgePoint(x + 52, -1) - const Offset(0, 8), 5,
      Paint()..color = const Color(0xFFBFC4AE));
}

void paintStreetProp(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  final base = road.edgePoint(x, -1);
  canvas.drawLine(
      base + const Offset(0, 4),
      base - const Offset(0, 44),
      Paint()
        ..color = const Color(0xFF5A6068)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round);
  if (index.isEven) {
    canvas.drawCircle(base - const Offset(0, 50), 7,
        Paint()..color = const Color(0xFFF7E3A6));
  } else {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(base.dx - 9, base.dy - 36, 18, 12),
            const Radius.circular(3)),
        Paint()..color = const Color(0xFFD76A5A));
  }
}

/// Clouds drift across the sky band, which is the strip above the horizon.
void paintClouds(Canvas canvas, ReturnHomeRoad road) {
  final w = road.worldWidth;
  final h = road.viewportHeight;
  for (var i = 0; i < 6; i++) {
    final center = Offset(w * (.05 + i * .17), h * (.06 + (i % 3) * .055));
    paintPuffyCloud(canvas, center, 120 + (i % 3) * 18.0,
        seed: i + 10, opacity: .9);
  }
}

void paintFlowers(Canvas canvas, ReturnHomeRoad road) {
  final w = road.worldWidth;
  final h = road.viewportHeight;
  final stem = Paint()
    ..color = const Color(0xFF4D8B4B)
    ..strokeWidth = 2;
  for (var i = 0; i < 40; i++) {
    final x = w * (.01 + (i * .0247) % .98);
    final y = h * (.80 + (i % 3) * .05);
    canvas.drawLine(Offset(x, y + 12), Offset(x, y), stem);
    canvas.drawCircle(
        Offset(x, y), 4, Paint()..color = const Color(0xFFFFC1C7));
    canvas.drawCircle(
        Offset(x + 4, y + 2), 3, Paint()..color = const Color(0xFFFFE49A));
  }
}

/// Tall bamboo culms on both sides with a few leaf sprays.
void paintBamboo(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  final h = road.viewportHeight;
  for (final side in [-1.0, 1.0]) {
    for (var k = 0; k < 3; k++) {
      final bx = x + k * 26.0 + (index % 2) * 9;
      final base = road.edgePoint(bx, side) + Offset(0, side * 8);
      final top =
          side < 0 ? base - Offset(0, h * .2) : base + Offset(0, h * .1);
      final stalk = Paint()
        ..color = k.isEven ? const Color(0xFF6FA84B) : const Color(0xFF85BC59)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(base, top, stalk);
      final joint = Paint()
        ..color = const Color(0xFF4E7F35)
        ..strokeWidth = 7;
      for (var j = 1; j < 4; j++) {
        final p = Offset.lerp(base, top, j / 4)!;
        canvas.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), joint);
      }
      final leaf = Paint()..color = const Color(0xFF4F9343);
      canvas.drawOval(
          Rect.fromCenter(
              center: top + const Offset(8, 0), width: 18, height: 6),
          leaf);
      canvas.drawOval(
          Rect.fromCenter(
              center: top - const Offset(7, -3), width: 16, height: 5),
          leaf);
    }
  }
}

/// A wooden bridge: water under both edges, planks across and handrails.
void paintBridgeSpan(Canvas canvas, ReturnHomeRoad road, double x0, double x1) {
  final h = road.viewportHeight;
  final water = Paint()..color = const Color(0xFF5FB4D0);
  for (final side in [-1.0, 1.0]) {
    final a = road.edgePoint(x0, side);
    final b = road.edgePoint(x1, side);
    canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx, b.dy + side * h * .09)
          ..lineTo(a.dx, a.dy + side * h * .09)
          ..close(),
        water);
  }
  final plank = Paint()
    ..color = const Color(0x667A4E2C)
    ..strokeWidth = 2;
  for (var x = x0; x < x1; x += 14) {
    canvas.drawLine(road.edgePoint(x, -1), road.edgePoint(x, 1), plank);
  }
  final rail = Paint()
    ..color = const Color(0xFF7A4E2C)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  for (final side in [-1.0, 1.0]) {
    final a = road.edgePoint(x0, side) + Offset(0, side * 2);
    final b = road.edgePoint(x1, side) + Offset(0, side * 2);
    canvas.drawLine(a - const Offset(0, 14), b - const Offset(0, 14), rail);
    canvas.drawLine(a, a - const Offset(0, 16), rail);
  }
}

/// Wheat tufts and the odd hay bale along an open field.
void paintFieldProp(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  final wheat = Paint()
    ..color = const Color(0xFFD9A93F)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  for (final side in [-1.0, 1.0]) {
    for (var k = 0; k < 5; k++) {
      final base = road.edgePoint(x + k * 18.0, side) + Offset(0, side * 12);
      canvas.drawLine(base, base + const Offset(2, -14), wheat);
      canvas.drawOval(
          Rect.fromCenter(
              center: base + const Offset(2, -16), width: 4, height: 8),
          Paint()..color = const Color(0xFFE8C063));
    }
  }
  if (index % 3 == 0) {
    final bale = road.edgePoint(x + 50, 1) + const Offset(0, 34);
    canvas.drawCircle(bale, 15, Paint()..color = const Color(0xFFD8B256));
    canvas.drawCircle(
        bale,
        9,
        Paint()
          ..color = const Color(0xFFB88F38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}

/// Small houses and brick walls on the village street.
void paintVillageProp(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  final base = road.edgePoint(x, -1) - const Offset(0, 6);
  if (index.isEven) {
    final colors = [const Color(0xFFF1D7B0), const Color(0xFFE7C3A3)];
    canvas.drawRect(Rect.fromLTWH(base.dx - 26, base.dy - 34, 52, 34),
        Paint()..color = colors[index % 4 ~/ 2]);
    canvas.drawPath(
        Path()
          ..moveTo(base.dx - 32, base.dy - 34)
          ..lineTo(base.dx, base.dy - 56)
          ..lineTo(base.dx + 32, base.dy - 34)
          ..close(),
        Paint()..color = const Color(0xFFB4533F));
    canvas.drawRect(Rect.fromLTWH(base.dx - 6, base.dy - 18, 12, 18),
        Paint()..color = const Color(0xFF7D4A33));
  } else {
    final brick = Paint()..color = const Color(0xFFA9614B);
    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRect(
            Rect.fromLTWH(base.dx - 30 + c * 15.0 + (r.isOdd ? 7 : 0),
                base.dy - 14 - r * 8.0, 13, 6),
            brick);
      }
    }
  }
}

/// The last quiet lane: low hedges and flower pots by the doorsteps.
void paintLaneProp(Canvas canvas, ReturnHomeRoad road, double x, int index) {
  for (final side in [-1.0, 1.0]) {
    final base = road.edgePoint(x, side) + Offset(0, side * 10);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: base, width: 70, height: 16),
            const Radius.circular(8)),
        Paint()..color = const Color(0xFF5E9B54));
  }
  final pot = road.edgePoint(x + 56, -1) - const Offset(0, 8);
  canvas.drawRect(Rect.fromCenter(center: pot, width: 14, height: 12),
      Paint()..color = const Color(0xFFC0714A));
  canvas.drawCircle(
      pot - const Offset(0, 9),
      5,
      Paint()
        ..color =
            index.isEven ? const Color(0xFFFF9CA8) : const Color(0xFFFFE07A));
}
