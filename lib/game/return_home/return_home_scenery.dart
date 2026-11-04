import 'dart:math';

import 'package:flutter/painting.dart';

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
    case ReturnHomeScenery.stream:
      paintStreamReeds(canvas, road, x);
    case ReturnHomeScenery.street:
      paintStreetProp(canvas, road, x, index);
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
    final top = base - Offset(0, h * .12);
    canvas.drawLine(
        base,
        top,
        Paint()
          ..color = const Color(0xFF8C6245)
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round);
    for (var k = 0; k < 3; k++) {
      canvas.drawCircle(top + Offset((k - 1) * 17.0, k == 1 ? -9 : 4), 23,
          Paint()..color = const Color(0xFF4E9663));
    }
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
  final paint = Paint()..color = const Color(0xBFFFFFFF);
  for (var i = 0; i < 6; i++) {
    final center = Offset(w * (.05 + i * .17), h * (.06 + (i % 3) * .055));
    canvas.drawOval(
        Rect.fromCenter(center: center, width: 118, height: 30), paint);
    canvas.drawCircle(center + const Offset(-35, 0), 20, paint);
    canvas.drawCircle(center + const Offset(4, -10), 27, paint);
    canvas.drawCircle(center + const Offset(39, 2), 17, paint);
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

/// The destination at the end of the run, seated on the lane's top edge so it
/// still reads as "home" now that the road curves.
void paintHouse(Canvas canvas, ReturnHomeRoad road) {
  final w = road.worldWidth;
  final h = road.viewportHeight;
  canvas.save();
  canvas.translate(0, road.topEdge(w - 100) - (h * .30 + 62));
  canvas.drawOval(Rect.fromLTWH(w - 178, h * .30 + 52, 150, 22),
      Paint()..color = const Color(0x33604432));
  canvas.drawPath(
      Path()
        ..moveTo(w - 168, h * .30)
        ..lineTo(w - 102, h * .14)
        ..lineTo(w - 36, h * .30)
        ..close(),
      Paint()..color = const Color(0xFFB96D4B));
  canvas.drawPath(
      Path()
        ..moveTo(w - 168, h * .30)
        ..lineTo(w - 102, h * .14)
        ..lineTo(w - 82, h * .22)
        ..lineTo(w - 140, h * .30)
        ..close(),
      Paint()..color = const Color(0xFFD98B59));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w - 155, h * .30, 106, 62), const Radius.circular(5)),
      Paint()..color = const Color(0xFFFFE5A6));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w - 112, h * .35, 28, 42), const Radius.circular(10)),
      Paint()..color = const Color(0xFF9B6248));
  canvas.drawCircle(
      Offset(w - 90, h * .43), 3, Paint()..color = const Color(0xFFFFD05A));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w - 151, h * .34, 22, 18), const Radius.circular(2)),
      Paint()..color = const Color(0xFF76B8B0));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w - 77, h * .34, 22, 18), const Radius.circular(2)),
      Paint()..color = const Color(0xFF76B8B0));
  final welcome = Paint()
    ..color = const Color(0xFFF4D78F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  canvas.drawLine(Offset(w - 144, h * .29), Offset(w - 60, h * .29), welcome);
  canvas.drawLine(Offset(w - 137, h * .29), Offset(w - 137, h * .36), welcome);
  canvas.drawLine(Offset(w - 67, h * .29), Offset(w - 67, h * .36), welcome);
  canvas.restore();
}
