import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import '../../fishing/fishing_river.dart';
import '../../game/world/nature_art.dart';
import 'fishing_coast_art.dart';
import 'fishing_river_details.dart';
import 'fishing_mangrove_art.dart';
import 'fishing_rocky_bay_art.dart';

/// Recorded once per stretch; seeds and world positions agree across seams.
ui.Picture recordFishingRiver(int section) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final left = section * FishingRiver.sectionLength;
  final right = left + FishingRiver.sectionLength;
  canvas.clipRect(
      Rect.fromLTWH(left, 0, FishingRiver.sectionLength, FishingRiver.height),
      doAntiAlias: false);
  _paintLandscape(canvas, left, right);
  return recorder.endRecording();
}

double _blend(double x) {
  final t = ((x - 1560) / 480).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

Color _tone(double x, Color first, Color second) => Color.lerp(
    Color.lerp(first, second, _blend(x)),
    const Color(0xFFE4D4A5),
    FishingRiver.coastBlend(x))!;

Path _strip(double left, double right, double Function(double) upper,
    double Function(double) lower) {
  final path = Path()..moveTo(left, upper(left));
  for (var x = left + 8; x < right; x += 8) {
    path.lineTo(x, upper(x));
  }
  path.lineTo(right, upper(right));
  path.lineTo(right, lower(right));
  for (var x = right - 8; x > left; x -= 8) {
    path.lineTo(x, lower(x));
  }
  return path
    ..lineTo(left, lower(left))
    ..close();
}

void _paintLandscape(Canvas canvas, double left, double right) {
  final from = left - 180, to = right + 180;
  final p = Paint();
  // Layered land and horizon, with a gentle palette change between sections.
  for (var x = from; x < to; x += 20) {
    final sky = Rect.fromLTWH(x, 0, 21, 130);
    canvas.drawRect(
        sky,
        p
          ..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter,
              const [Color(0xFF9FD7DA), Color(0xFFE1EEDA)]));
    p.shader = null;
    final groundTop = 100 + FishingRiver.coastBlend(x) * 25;
    canvas.drawRect(
        Rect.fromLTWH(x, groundTop, 21, FishingRiver.height - groundTop),
        p..color = _tone(x, const Color(0xFFA7BF78), const Color(0xFF8DA979)));
  }
  for (var layer = 0; layer < 2; layer++) {
    canvas.drawPath(
        _strip(
            from,
            to,
            (x) =>
                (layer == 0 ? 78 : 91) +
                math.sin(x / (layer == 0 ? 210 : 140)) * 13 +
                math.sin(x / 51) * (layer == 0 ? 3 : 5),
            (_) => 126),
        Paint()
          ..shader = ui.Gradient.linear(
              const Offset(1560, 0),
              const Offset(4080, 0),
              layer == 0
                  ? const [
                      Color(0xFFA0C6AF),
                      Color(0xFFA0B9B0),
                      Color(0xFFA0B9B0),
                      Color(0x00A0B9B0)
                    ]
                  : const [
                      Color(0xFF89B69B),
                      Color(0xFF8EA9A2),
                      Color(0xFF8EA9A2),
                      Color(0x008EA9A2)
                    ],
              const [0, 480 / 2520, 1800 / 2520, 1]));
  }
  for (var i = (from / 420).floor(); i <= (to / 420).ceil(); i++) {
    paintPuffyCloud(
        canvas, Offset(i * 420 + 150, 43 + math.sin(i * 2.0) * 10), 130,
        seed: i + 300, opacity: .65);
  }
  // Wide soil paths sit behind the banks, never across navigable water.
  canvas.drawPath(
      _strip(from, to, (x) => FishingRiver.top(x) - 48,
          (x) => FishingRiver.top(x) - 23),
      Paint()
        ..shader = ui.Gradient.linear(
            const Offset(FishingRiver.seaStart - 240, 0),
            const Offset(FishingRiver.seaStart + 360, 0),
            const [Color(0xFFC7BE8D), Color(0x00C7BE8D)]));
  canvas.drawPath(
      _strip(from, to, (x) => FishingRiver.bottom(x) + 52,
          (x) => FishingRiver.bottom(x) + 73),
      Paint()
        ..shader = ui.Gradient.linear(
            const Offset(FishingRiver.seaStart - 240, 0),
            const Offset(FishingRiver.seaStart + 360, 0),
            const [Color(0xFFD8C898), Color(0x00D8C898)]));
  // Exposed sandy shelf, dark damp rim, deep channel, then shallow margins.
  canvas.drawPath(
      _strip(
          from,
          to,
          (x) => FishingRiver.top(x) - 14 * (1 - FishingRiver.coastBlend(x)),
          (x) => FishingRiver.bottom(x) + 14),
      p..color = const Color(0xFF8C9A65));
  canvas.drawPath(
      _strip(
          from,
          to,
          (x) => FishingRiver.top(x) - 8 * (1 - FishingRiver.coastBlend(x)),
          (x) => FishingRiver.bottom(x) + 8),
      p..color = const Color(0xFFE0CFA2));
  final water = _strip(from, to, FishingRiver.top, FishingRiver.bottom);
  canvas.drawPath(
      water,
      p
        ..shader = ui.Gradient.linear(
            const Offset(0, 200),
            const Offset(0, 1900),
            const [Color(0xFF478F98), Color(0xFF66B4B2), Color(0xFF91CDC0)],
            const [0, .5, 1]));
  p.shader = null;
  canvas.drawPath(
      water,
      Paint()
        ..shader = ui.Gradient.linear(
            const Offset(FishingRiver.seaStart - 240, 0),
            const Offset(FishingRiver.seaStart + 600, 0),
            const [Color(0x003C9FB9), Color(0xFF3C9FB9)]));
  for (final side in [-1, 1]) {
    double edge(double x) =>
        side < 0 ? FishingRiver.top(x) : FishingRiver.bottom(x);
    final shallows = _strip(
        from,
        to,
        (x) => side < 0 ? edge(x) : edge(x) - 16,
        (x) => side < 0
            ? edge(x) + 15 * (1 - FishingRiver.coastBlend(x))
            : edge(x));
    canvas.drawPath(shallows, p..color = const Color(0x446CD3BE));
    final rim = Path()..moveTo(from, edge(from) + side * 2);
    for (var x = from + 10; x <= to; x += 10) {
      rim.lineTo(x, edge(x) + side * 2);
    }
    canvas.drawPath(
        rim,
        Paint()
          ..shader = side < 0
              ? ui.Gradient.linear(
                  const Offset(FishingRiver.seaStart - 240, 0),
                  const Offset(FishingRiver.seaStart + 360, 0),
                  const [Color(0x99F0E7BF), Color(0x00F0E7BF)])
              : null
          ..color = const Color(0x99F0E7BF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
  final rng = math.Random(732);
  // Grass strokes, loose pebbles and clover stay off the river and paths.
  for (var i = 0; i < 4500; i++) {
    final x = rng.nextDouble() * FishingRiver.seaStart;
    final y = 130 + rng.nextDouble() * (FishingRiver.height - 130);
    if (x < from || x > to) continue;
    if (y > FishingRiver.top(x) - 18 && y < FishingRiver.bottom(x) + 23) {
      continue;
    }
    if ((y - FishingRiver.bottom(x) - 62).abs() < 13 ||
        (y - FishingRiver.top(x) + 35).abs() < 16) {
      continue;
    }
    final color = _tone(x, const Color(0x6681A15B), const Color(0x666C8D59));
    canvas.drawLine(
        Offset(x, y),
        Offset(x - 2, y - 3 - rng.nextDouble() * 4),
        Paint()
          ..color = color
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(x, y),
        Offset(x + 3, y - 4),
        Paint()
          ..color = color
          ..strokeWidth = 1.2);
    if (i % 7 == 0) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x + 5, y), width: 5, height: 2),
          p..color = const Color(0x779FAD7C));
    }
  }
  // Stable shoreline stones and reeds connect both banks visually.
  for (var i = (from / 55).floor(); i <= (to / 55).ceil(); i++) {
    final x = i * 55.0 + 13;
    if (x >= FishingRiver.seaStart - 60) continue;
    final side = i.isEven ? -1.0 : 1.0;
    final y = side < 0 ? FishingRiver.top(x) - 3 : FishingRiver.bottom(x) + 5;
    _stone(canvas, Offset(x, y), 9 + (i % 3) * 3.0);
    if (i % 3 == 0) _reeds(canvas, Offset(x + 17, y + side * 7), seed: i);
  }
  // Far bank: cottage gardens become bamboo and a rocky green ridge.
  for (var i = (from / 175).floor(); i <= (to / 175).ceil(); i++) {
    final x = i * 175.0 + 80;
    if (x >= FishingRiver.seaStart - 40) continue;
    final y = FishingRiver.top(x) - 15;
    if (x < 1780) {
      if (i % 3 != 1) {
        paintLeafyTree(canvas, Offset(x, y), 94 + (i % 3) * 12, seed: i + 91);
      }
    } else {
      _bamboo(canvas, Offset(x, y), 105 + i % 3 * 11.0, seed: i);
      if (i.isEven) _boulder(canvas, Offset(x - 55, y - 14), 45);
    }
  }
  for (final x in [330.0, 900.0, 1430.0]) {
    if (x < from || x > to) continue;
    final base = Offset(x, FishingRiver.top(x) - 43);
    _cottage(canvas, base,
        x == 900 ? const Color(0xFFA36D58) : const Color(0xFFB87C56));
    _fence(canvas, base + const Offset(-115, 26), 85);
    _garden(canvas, base + const Offset(79, 5));
  }
  if (left < 2700 && right > 2300) {
    const x = 2490.0;
    _cottage(
        canvas, Offset(x, FishingRiver.top(x) - 38), const Color(0xFF797F66),
        small: true);
  }
  // Near bank: flower meadow gives way to golden rice terraces.
  for (var i = (from / 210).floor(); i <= (to / 210).ceil(); i++) {
    final x = i * 210.0 + 45;
    if (x >= FishingRiver.seaStart - 160) continue;
    final y = FishingRiver.bottom(x);
    if (x < 1800) {
      _flowers(canvas, Offset(x, y + 36), seed: i);
      if (i % 3 == 0) {
        paintLeafyTree(canvas, Offset(x + 90, y + 157), 83, seed: i + 51);
      }
      if (i % 3 == 1) _garden(canvas, Offset(x + 70, y + 100));
    } else {
      _rice(canvas, Offset(x, y + 88), seed: i);
      if (i % 3 == 0) _bamboo(canvas, Offset(x + 120, y + 157), 70, seed: i);
    }
  }
  for (final x in [FishingRiver.startDockX, 1130.0, 2110.0, 3340.0]) {
    if (x < from || x > to) continue;
    _dock(canvas, Offset(x, FishingRiver.bottom(x) - 15));
  }
  if (left < 2850 && right > 2500) {
    _watermill(canvas, Offset(2680, FishingRiver.bottom(2680) + 43));
  }
  // A small, open lotus patch hugs each bank rather than blocking the route.
  for (final x in [620.0, 1510.0, 2240.0, 3110.0]) {
    if (x < from || x > to) continue;
    _lotus(canvas, Offset(x, FishingRiver.bottom(x) - 10));
  }
  paintFishingCoast(canvas, from, to);
  paintRiverDetails(canvas, from, to);
  paintMangrove(canvas, left, right);
  paintRockyBay(canvas, left, right);
}

void _stone(Canvas c, Offset p, double size) {
  c.drawOval(
      Rect.fromCenter(
          center: p + const Offset(0, 2), width: size * 1.8, height: size * .7),
      Paint()..color = const Color(0x333E5346));
  c.drawOval(Rect.fromCenter(center: p, width: size * 1.7, height: size * .85),
      Paint()..color = const Color(0xFFAEB398));
  c.drawArc(
      Rect.fromCenter(
          center: p - const Offset(1, 1), width: size * 1.2, height: size * .5),
      math.pi,
      math.pi * .8,
      false,
      Paint()
        ..color = const Color(0xFFD5D3B3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

void _reeds(Canvas c, Offset p, {required int seed}) {
  final rng = math.Random(seed);
  for (var i = 0; i < 6; i++) {
    final dx = (i - 3) * 4.0;
    final height = 17 + rng.nextDouble() * 19;
    final tip = p + Offset(dx + dx * .4, -height);
    c.drawLine(
        p + Offset(dx, 0),
        tip,
        Paint()
          ..color = const Color(0xFF6B8C4D)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    if (i.isEven) {
      c.drawLine(
          tip,
          tip - const Offset(0, 7),
          Paint()
            ..color = const Color(0xFF8C6C3B)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
  }
}

void _bamboo(Canvas c, Offset p, double height, {required int seed}) {
  final rng = math.Random(seed);
  for (var i = 0; i < 6; i++) {
    final h = height * (.7 + rng.nextDouble() * .3);
    final base = p + Offset((i - 3) * 9.0, 0);
    final top = base + Offset((i - 2) * 3.0, -h);
    c.drawLine(
        base,
        top,
        Paint()
          ..color = const Color(0xFF557F4D)
          ..strokeWidth = 5);
    c.drawLine(
        base - const Offset(1, 0),
        top - const Offset(1, 0),
        Paint()
          ..color = const Color(0xFFACC681)
          ..strokeWidth = 1.5);
    for (var j = 1; j <= 4; j++) {
      final joint = Offset.lerp(base, top, j / 5)!;
      c.drawLine(
          joint - const Offset(3, 0),
          joint + const Offset(3, 0),
          Paint()
            ..color = const Color(0xFFCED79F)
            ..strokeWidth = 1.5);
      for (final side in [-1, 1]) {
        final leaf = Path()
          ..moveTo(joint.dx, joint.dy)
          ..quadraticBezierTo(joint.dx + side * 14, joint.dy - 13,
              joint.dx + side * 26, joint.dy - 7)
          ..quadraticBezierTo(
              joint.dx + side * 13, joint.dy - 2, joint.dx, joint.dy);
        c.drawPath(
            leaf,
            Paint()
              ..color =
                  i.isEven ? const Color(0xFF548958) : const Color(0xFF75A368));
      }
    }
  }
}

void _boulder(Canvas c, Offset p, double size) {
  final shape = Path()
    ..moveTo(p.dx - size, p.dy)
    ..lineTo(p.dx - size * .7, p.dy - size * .7)
    ..lineTo(p.dx, p.dy - size * 1.1)
    ..lineTo(p.dx + size * .7, p.dy - size * .8)
    ..lineTo(p.dx + size, p.dy)
    ..close();
  c.drawPath(shape, Paint()..color = const Color(0xFF879A92));
  c.drawPath(
      Path()
        ..moveTo(p.dx, p.dy - size * 1.1)
        ..lineTo(p.dx + size * .3, p.dy - size * .2)
        ..lineTo(p.dx + size, p.dy)
        ..close(),
      Paint()..color = const Color(0xFF6F8580));
  c.drawOval(
      Rect.fromCenter(
          center: p - Offset(size * .45, size * .1), width: size, height: 9),
      Paint()..color = const Color(0xFF738E60));
}

void _cottage(Canvas c, Offset base, Color roof, {bool small = false}) {
  c.save();
  c.translate(base.dx, base.dy);
  if (small) c.scale(.8);
  final p = Paint();
  c.drawOval(const Rect.fromLTWH(-80, -4, 162, 22),
      p..color = const Color(0x334E5037));
  c.drawRect(const Rect.fromLTWH(-57, -65, 114, 66),
      p..color = const Color(0xFFF0D9AA));
  c.drawRect(
      const Rect.fromLTWH(25, -65, 32, 66), p..color = const Color(0xFFD1B58A));
  final roofPath = Path()
    ..moveTo(-73, -61)
    ..lineTo(-45, -106)
    ..lineTo(38, -106)
    ..lineTo(76, -61)
    ..close();
  c.drawPath(roofPath, p..color = roof);
  c.drawPath(
      roofPath,
      Paint()
        ..color = const Color(0xFF785941)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  for (var y = -97.0; y < -64; y += 9) {
    c.drawLine(
        Offset(-46 - (-97 - y) * .55, y),
        Offset(40 + (-97 - y) * -.6, y),
        Paint()
          ..color = const Color(0x55FFD7A0)
          ..strokeWidth = 2);
  }
  c.drawRect(
      const Rect.fromLTWH(-9, -40, 24, 41), p..color = const Color(0xFF8C7656));
  c.drawRect(
      const Rect.fromLTWH(-5, -37, 16, 36), p..color = const Color(0xFF655E4A));
  c.drawCircle(const Offset(7, -18), 1.7, p..color = const Color(0xFFE9C87D));
  for (final x in [-40.0, 29.0]) {
    c.drawRect(
        Rect.fromLTWH(x, -44, 20, 22), p..color = const Color(0xFF5B8990));
    c.drawRect(
        Rect.fromLTWH(x, -44, 20, 22),
        Paint()
          ..color = const Color(0xFFAA8359)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawLine(
        Offset(x + 10, -44),
        Offset(x + 10, -22),
        Paint()
          ..color = const Color(0xFFE5D3A6)
          ..strokeWidth = 2);
    c.drawLine(
        Offset(x, -33),
        Offset(x + 20, -33),
        Paint()
          ..color = const Color(0xFFE5D3A6)
          ..strokeWidth = 2);
  }
  c.drawRect(const Rect.fromLTWH(28, -126, 12, 28),
      p..color = const Color(0xFFA4937A));
  c.drawRect(
      const Rect.fromLTWH(25, -128, 18, 5), p..color = const Color(0xFF8D7D68));
  for (var i = 0; i < 3; i++) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-13 - i * 5, 2 + i * 4, 33 + i * 10, 4),
            const Radius.circular(2)),
        p..color = const Color(0xFFB7AA87));
  }
  c.drawOval(
      const Rect.fromLTWH(-66, -9, 17, 14), p..color = const Color(0xFFB78959));
  c.drawOval(const Rect.fromLTWH(-63, -14, 12, 12),
      p..color = const Color(0xFF71995D));
  c.restore();
}

void _fence(Canvas c, Offset p, double width) {
  final rail = Paint()
    ..color = const Color(0xFFBD9867)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  c.drawLine(p - const Offset(0, 17), p + Offset(width, -17), rail);
  c.drawLine(p - const Offset(0, 7), p + Offset(width, -7), rail);
  for (var x = 0.0; x <= width; x += 22) {
    c.drawLine(
        p + Offset(x, 3),
        p + Offset(x, -26),
        Paint()
          ..color = const Color(0xFF92764D)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
  }
}

void _garden(Canvas c, Offset p) {
  c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 35, p.dy - 16, 76, 36),
          const Radius.circular(8)),
      Paint()..color = const Color(0xFFAD9368));
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 5; col++) {
      final v = p + Offset(-26 + col * 14.0, -9 + row * 11.0);
      c.drawOval(
          Rect.fromCenter(center: v, width: 12, height: 8),
          Paint()
            ..color =
                row.isEven ? const Color(0xFF66915B) : const Color(0xFF87AA66));
      c.drawLine(
          v,
          v - const Offset(0, 4),
          Paint()
            ..color = const Color(0xFFB3C57A)
            ..strokeWidth = 1.3);
    }
  }
}

void _flowers(Canvas c, Offset p, {required int seed}) {
  final rng = math.Random(seed + 50);
  for (var i = 0; i < 18; i++) {
    final v = p + Offset(rng.nextDouble() * 100 - 50, rng.nextDouble() * 23);
    final tip = v - Offset(0, 6 + rng.nextDouble() * 8);
    c.drawLine(
        v,
        tip,
        Paint()
          ..color = const Color(0xFF6D9751)
          ..strokeWidth = 1.4);
    final color = [
      const Color(0xFFFFE7A1),
      const Color(0xFFEFAEA1),
      const Color(0xFFF1EAD4)
    ][i % 3];
    for (var j = 0; j < 5; j++) {
      c.drawCircle(tip + Offset.fromDirection(j * math.pi * 2 / 5, 2.5), 2.5,
          Paint()..color = color);
    }
    c.drawCircle(tip, 1.7, Paint()..color = const Color(0xFFD6AC4E));
  }
}

void _rice(Canvas c, Offset p, {required int seed}) {
  c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(p.dx - 55, p.dy - 13, 142, 67),
          const Radius.circular(12)),
      Paint()..color = const Color(0xFFB0AA60));
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 10; col++) {
      final base = p + Offset(-45 + col * 13.0, row * 14.0);
      final tip = base - const Offset(0, 14);
      c.drawLine(
          base,
          tip,
          Paint()
            ..color = const Color(0xFF8A964B)
            ..strokeWidth = 1.5);
      for (var j = 0; j < 3; j++) {
        c.drawLine(
            tip + Offset(0, j * 3.0),
            tip + Offset(5, 2 + j * 3.0),
            Paint()
              ..color = (seed + col).isEven
                  ? const Color(0xFFE9CD73)
                  : const Color(0xFFD9BD62)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round);
      }
    }
  }
}

void _dock(Canvas c, Offset p) {
  c.drawRect(Rect.fromLTWH(p.dx - 26, p.dy + 5, 58, 63),
      Paint()..color = const Color(0x33424B39));
  c.drawRect(Rect.fromLTWH(p.dx - 27, p.dy, 54, 64),
      Paint()..color = const Color(0xFFA67C4E));
  for (var i = 0; i < 8; i++) {
    c.drawRect(
        Rect.fromLTWH(p.dx - 26, p.dy + i * 8.0, 52, 6.5),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFC39B64) : const Color(0xFFB58C58));
    for (final side in [-1, 1]) {
      c.drawCircle(p + Offset(side * 21, 3 + i * 8.0), 1,
          Paint()..color = const Color(0xFF765B3D));
    }
  }
  for (final side in [-1, 1]) {
    c.drawLine(
        p + Offset(side * 28, 61),
        p + Offset(side * 28, -10),
        Paint()
          ..color = const Color(0xFF8D6844)
          ..strokeWidth = 5);
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset(side * 28, -10), width: 7, height: 4),
        Paint()..color = const Color(0xFFD4B27B));
  }
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(17, 43), width: 17, height: 10),
      Paint()
        ..color = const Color(0xFF8C7653)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

void _watermill(Canvas c, Offset p) {
  final paint = Paint()..color = const Color(0xFF9D784C);
  c.drawRect(Rect.fromLTWH(p.dx - 50, p.dy - 24, 45, 44), paint);
  c.drawPath(
      Path()
        ..moveTo(p.dx - 59, p.dy - 24)
        ..lineTo(p.dx - 29, p.dy - 56)
        ..lineTo(p.dx + 2, p.dy - 24)
        ..close(),
      paint..color = const Color(0xFF76896E));
}

void _lotus(Canvas c, Offset p) {
  for (var i = 0; i < 4; i++) {
    c.drawArc(
        Rect.fromCenter(
            center: p + Offset((i - 2) * 17.0, math.sin(i * 2.0) * 5),
            width: 32,
            height: 16),
        .3,
        math.pi * 1.8,
        true,
        Paint()
          ..color =
              i.isEven ? const Color(0xFF5D9E73) : const Color(0xFF7AB583));
  }
  for (var i = 0; i < 5; i++) {
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset.fromDirection(i * math.pi * 2 / 5, 4),
            width: 9,
            height: 6),
        Paint()..color = const Color(0xFFF2BFC5));
  }
  c.drawCircle(p, 3, Paint()..color = const Color(0xFFFFDEA0));
}
