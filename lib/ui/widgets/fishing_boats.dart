import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../../fishing/fishing_boat.dart';
import 'fishing_art_kit.dart';
import 'fishing_boat_art.dart';
import 'fishing_river_scene.dart';

/// Part of [boat] drawn under the cat (origin = boat point).
void paintBoatBack(Canvas c, FishingBoat boat) => switch (boat) {
      FishingBoat.basket => paintBasketBoatBack(c),
      FishingBoat.paper => paintPaperBoatBack(c),
      FishingBoat.melon => paintMelonBoatBack(c),
    };

/// Part of [boat] drawn over the cat, so the cat sits inside.
void paintBoatFront(Canvas c, FishingBoat boat) => switch (boat) {
      FishingBoat.basket => paintBasketBoatFront(c),
      FishingBoat.paper => paintPaperBoatFront(c),
      FishingBoat.melon => paintMelonBoatFront(c),
    };

// Half watermelon: red flesh with seeds and a pale rind ring on top, striped
// green rind as the hull, a leaf flag on a popsicle-stick mast.

const _rim = Rect.fromLTWH(-60, -24, 120, 30); // centre y = -9
const _depth = 20.0;
final _bottom = _rim.shift(const Offset(0, _depth)).deflate(6);
final _wall = Path()
  ..addArc(_rim, 0, math.pi)
  ..arcTo(_bottom, math.pi, -math.pi, false)
  ..close();

void paintMelonBoatBack(Canvas c) {
  c.drawOval(const Rect.fromLTWH(-64, 6, 128, 30), fillPaint(0x40345A5C));
  c.drawOval(const Rect.fromLTWH(-62, 6, 124, 26), strokePaint(0x88E9FFF7, 2));
  // Mast at the stern: a popsicle stick with a leaf flag.
  c.drawLine(const Offset(-38, -14), const Offset(-42, -78),
      strokePaint(0xFF8A5A33, 5.5));
  c.drawLine(const Offset(-38, -14), const Offset(-42, -78),
      strokePaint(0xFFE8C88E, 3.5));
  final leaf = Path()
    ..moveTo(-41, -76)
    ..quadraticBezierTo(-14, -84, -4, -66)
    ..quadraticBezierTo(-20, -56, -41, -60)
    ..close();
  c.drawPath(leaf, fillPaint(0xFF6DB04A));
  c.drawLine(const Offset(-40, -68), const Offset(-8, -67),
      strokePaint(0xFF3F7A2E, 1.4));
  c.drawPath(leaf, strokePaint(0xFF2F5A22, 1.6));
  // Back of the hull, then the top: rind ring and juicy flesh.
  c.drawPath(
      Path()
        ..addOval(_rim)
        ..addOval(_bottom),
      fillPaint(0xFF2F6B2A));
  c.drawOval(_rim, fillPaint(0xFF3E8A35));
  c.drawOval(_rim.deflate(3), fillPaint(0xFFF2F5D8));
  final flesh = _rim.deflate(7);
  c.drawOval(flesh, fillPaint(0xFFF0505A));
  c.drawOval(
      Rect.fromCenter(
          center: flesh.center + const Offset(0, 3),
          width: flesh.width - 18,
          height: flesh.height - 8),
      fillPaint(0xFFF7737A));
  // A bite out of the far rim.
  for (final x in [18.0, 28.0]) {
    c.drawCircle(Offset(x, -23), 5.5, fillPaint(0xFFF7737A));
  }
  // Seeds around the edge of the flesh.
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi * 2 / 12 + .2;
    final p = flesh.center +
        Offset(
            math.cos(a) * flesh.width * .34, math.sin(a) * flesh.height * .3);
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(a + math.pi / 2);
    c.drawOval(
        const Rect.fromLTWH(-1.6, -2.8, 3.2, 5.6), fillPaint(0xFF2B1D1A));
    c.restore();
  }
  c.drawOval(_rim, strokePaint(0xFF1F4A1C, 2.4));
}

void paintMelonBoatFront(Canvas c) {
  c.drawPath(
      _wall,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4FA043), Color(0xFF2B6A28)])
            .createShader(Rect.fromLTRB(-60, -10, 60, _bottom.bottom)));
  // Dark zigzag stripes running down the rind.
  c.save();
  c.clipPath(_wall);
  for (var i = -5; i <= 5; i++) {
    final x = i * 11.0;
    final stripe = Path()..moveTo(x, -10);
    for (var k = 1; k <= 5; k++) {
      stripe.lineTo(x * (1 - k * .03) + (k.isEven ? -3 : 3), -10 + k * 6.0);
    }
    c.drawPath(stripe, strokePaint(0xFF1F4F1D, 4));
  }
  c.restore();
  c.drawArc(_bottom.deflate(2), math.pi * .2, math.pi * .45, false,
      strokePaint(0x55FFFFFF, 1.6));
  // Near rind lip: green skin over a pale ring.
  c.drawArc(_rim, 0, math.pi, false, strokePaint(0xFFF2F5D8, 4));
  c.drawArc(_rim.inflate(2), 0, math.pi, false, strokePaint(0xFF3E8A35, 2.4));
  c.drawPath(_wall, strokePaint(0xFF1F4A1C, 2));
}
