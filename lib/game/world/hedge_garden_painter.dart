import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_garden_painter.dart';
import 'shelter_map.dart';

/// Chapter 2: the usual garden lawn plus round flower bushes. Bush centres
/// come from [ShelterMap.hedge], so art and hiding spots always match.
class HedgeGardenPainter extends CustomPainter {
  const HedgeGardenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const ShelterGardenPainter().paint(canvas, size);
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    const map = ShelterMap.hedge;
    final r = map.bushRadius * 1000;
    for (var i = 0; i < map.bushes.length; i++) {
      _bush(canvas, Offset(map.bushes[i].dx * 1000, map.bushes[i].dy * 500), r,
          i);
    }
    // A winding gravel path makes the open lawn read as the safe route.
    final stones = Paint()..color = const Color(0x55FFF4DA);
    final random = math.Random(5);
    for (var i = 0; i < 26; i++) {
      final t = i / 25;
      final x = 120 + t * 760;
      final y = 420 - math.sin(t * math.pi * 2) * 40;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x + random.nextDouble() * 8, y),
              width: 18,
              height: 9),
          stones);
    }
    canvas.restore();
  }

  void _bush(Canvas c, Offset center, double r, int seed) {
    c.drawOval(
        Rect.fromCenter(
            center: center + Offset(0, r * .55),
            width: r * 2.2,
            height: r * .7),
        Paint()..color = const Color(0x33402A14));
    final dark = Paint()..color = const Color(0xFF5E9152);
    final mid = Paint()..color = const Color(0xFF74A963);
    final light = Paint()..color = const Color(0xFF93C27B);
    // Leafy clumps, darkest at the back.
    for (final (dx, dy, k, paint) in [
      (-.55, .05, .55, dark),
      (.55, .05, .55, dark),
      (0.0, -.25, .62, dark),
      (-.35, .15, .55, mid),
      (.38, .18, .52, mid),
      (0.0, .05, .6, mid),
      (-.2, -.15, .38, light),
      (.25, -.1, .34, light),
    ]) {
      c.drawCircle(center + Offset(dx * r, dy * r), k * r, paint);
    }
    // Hole in the middle where peeking eyes show up.
    c.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, -4),
            width: r * .7,
            height: r * .42),
        Paint()..color = const Color(0xFF3E6B38));
    final random = math.Random(seed * 13 + 3);
    const petals = [Color(0xFFF2A3B3), Color(0xFFFFD36B), Color(0xFFFFFFFF)];
    for (var i = 0; i < 9; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final d = r * (.45 + random.nextDouble() * .45);
      final p = center + Offset(math.cos(a) * d, math.sin(a) * d * .8);
      if ((p - center).distance < r * .4) continue;
      final color = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        c.drawCircle(p + Offset.fromDirection(k * 1.256, 3.2), 2.6,
            Paint()..color = color);
      }
      c.drawCircle(p, 2, Paint()..color = const Color(0xFFE9A13A));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
