import '../../fishing/fishing_place.dart';
import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../../fishing/fishing_river.dart';
import 'fishing_art_kit.dart';
import 'fishing_boat_art.dart';
import 'fishing_river_scene.dart';

// Village harbour: the boathouse (tap it to switch boats) with a beacon tower,
// and harbour bits on the starting pier. Everything here is static and is
// recorded into the cached landscape chunks.

const _ink = 0xFF4A2F1C;

/// Boathouse with a red tile roof, a stone base, a beacon tower and both
/// boats waiting inside the bay door.
void paintBoatHouse(Canvas c) {
  final b = FishingVisit.boatHouse.anchor;
  c.save();
  c.translate(b.dx, b.dy);
  // Ground shadow and a plank slipway out of the bay door.
  c.drawOval(const Rect.fromLTWH(-108, -8, 214, 26), fillPaint(0x334E5037));
  final ramp = Path()
    ..moveTo(-50, -2)
    ..lineTo(2, -2)
    ..lineTo(10, 16)
    ..lineTo(-58, 16)
    ..close();
  c.drawPath(ramp, fillPaint(0xFFB08A5A));
  for (var y = 2.0; y < 16; y += 5) {
    c.drawLine(Offset(-54 - y * .2, y), Offset(6 + y * .2, y),
        strokePaint(0x66704B28, 1.2));
  }
  c.drawPath(ramp, strokePaint(0xFF6E4A2A, 1.6));

  _tower(c);

  // Stone foundation.
  const base = Rect.fromLTWH(-84, -16, 146, 16);
  c.drawRect(base, fillPaint(0xFF9C9488));
  for (var i = 0; i < 9; i++) {
    final x = -84 + i * 16.0 + (i.isEven ? 0 : 4);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 1, -15, 14, 7), const Radius.circular(2)),
        fillPaint(0xFFB8B0A2));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 6, -7, 14, 6), const Radius.circular(2)),
        fillPaint(0xFFADA597));
  }
  c.drawRect(base, strokePaint(_ink, 2));

  // Plank walls with horizontal siding.
  const wall = Rect.fromLTWH(-80, -86, 138, 70);
  c.drawRect(wall, fillPaint(0xFFCF9A5F));
  for (var y = -86.0; y < -16; y += 9) {
    c.drawRect(Rect.fromLTWH(-80, y, 138, 4.5), fillPaint(0xFFC38C52));
    c.drawLine(
        Offset(-80, y + 9), Offset(58, y + 9), strokePaint(0x55704B28, 1));
  }
  c.drawRect(wall, strokePaint(_ink, 2.4));
  // Corner posts.
  for (final x in [-80.0, 58.0]) {
    c.drawRect(Rect.fromLTWH(x - 4, -88, 8, 72), fillPaint(0xFF8A5A33));
    c.drawRect(Rect.fromLTWH(x - 4, -88, 8, 72), strokePaint(_ink, 1.6));
  }

  // Arched bay door with the two boats waiting inside.
  final door = Path()
    ..moveTo(-58, -16)
    ..lineTo(-58, -50)
    ..arcToPoint(const Offset(6, -50), radius: const Radius.circular(34))
    ..lineTo(6, -16)
    ..close();
  c.drawPath(door, fillPaint(0xFF3E2C20));
  c.save();
  c.clipPath(door);
  c.drawRect(const Rect.fromLTWH(-58, -30, 64, 14), fillPaint(0xFF4F8E93));
  for (var x = -54.0; x < 6; x += 12) {
    c.drawLine(
        Offset(x, -24), Offset(x + 6, -24), strokePaint(0x88BFE6E0, 1.4));
  }
  c.drawCircle(const Offset(-26, -62), 30, fillPaint(0x22FFE1A0));
  c.restore();
  c.save();
  c.translate(-38, -26);
  c.scale(.2);
  paintPaperBoatBack(c);
  paintPaperBoatFront(c);
  c.restore();
  c.save();
  c.translate(-10, -26);
  c.scale(.2);
  paintBasketBoatBack(c);
  paintBasketBoatFront(c);
  c.restore();
  // Door frame and swung-open shutters.
  c.drawPath(door, strokePaint(0xFF6E4A2A, 4));
  for (final (x, dir) in [(-58.0, -1.0), (6.0, 1.0)]) {
    final leaf = Rect.fromLTRB(
        math.min(x, x + dir * 12), -64, math.max(x, x + dir * 12), -16);
    c.drawRect(leaf, fillPaint(0xFF7C9B6A));
    c.drawLine(leaf.topLeft, leaf.bottomRight, strokePaint(0xFF5C7A4E, 2));
    c.drawRect(leaf, strokePaint(_ink, 1.6));
  }

  // Life ring and a hanging lantern on the wall beside the door.
  const ring = Offset(36, -52);
  c.drawCircle(ring, 11, strokePaint(0xFFF4EFE6, 7));
  for (var k = 0; k < 4; k++) {
    c.drawArc(Rect.fromCircle(center: ring, radius: 11), k * math.pi / 2 + .3,
        .9, false, strokePaint(0xFFD9473A, 7.2)..strokeCap = StrokeCap.butt);
  }
  c.drawCircle(ring, 14.5, strokePaint(_ink, 1.2));
  c.drawCircle(ring, 7.5, strokePaint(_ink, 1.2));
  c.drawLine(const Offset(36, -72), const Offset(36, -63),
      strokePaint(0xFF6E4A2A, 1.5));
  _lantern(c, const Offset(18, -66));

  // Red tile gable roof with an anchor sign in the gable.
  final roof = Path()
    ..moveTo(-96, -80)
    ..lineTo(-11, -134)
    ..lineTo(74, -80)
    ..lineTo(64, -74)
    ..lineTo(-11, -122)
    ..lineTo(-86, -74)
    ..close();
  final gable = Path()
    ..moveTo(-84, -82)
    ..lineTo(-11, -126)
    ..lineTo(62, -82)
    ..close();
  c.drawPath(gable, fillPaint(0xFFE2B57A));
  c.save();
  c.clipPath(gable);
  for (var x = -84.0; x < 62; x += 8) {
    c.drawLine(Offset(x, -130), Offset(x, -80), strokePaint(0x44704B28, 1));
  }
  c.restore();
  c.drawPath(gable, strokePaint(_ink, 1.6));
  // Sign: anchor on a cream board.
  final sign = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-11, -100), width: 40, height: 22),
      const Radius.circular(4));
  c.drawRRect(sign, fillPaint(0xFFF2DDAE));
  c.drawRRect(sign, strokePaint(0xFF7A5533, 1.8));
  _anchor(c, const Offset(-11, -100), 8, 0xFF2F5E63);

  c.drawPath(roof, fillPaint(0xFFC4573F));
  c.save();
  c.clipPath(roof);
  for (var i = 0; i < 4; i++) {
    final k = i * 3.2;
    c.drawLine(Offset(-93 + k * 1.6, -78 - k), Offset(-11, -131 + k * .5),
        strokePaint(0x55FFD2B0, 1.2));
    c.drawLine(Offset(71 - k * 1.6, -78 - k), Offset(-11, -131 + k * .5),
        strokePaint(0x557A2A1E, 1.2));
  }
  c.restore();
  c.drawPath(roof, strokePaint(_ink, 2.4));
  // Crates, a barrel and a coiled rope by the door.
  _crate(c, const Offset(-74, 12), 18);
  _crate(c, const Offset(-74, -6), 14);
  _barrel(c, const Offset(-90, 14));
  _rope(c, const Offset(22, 6));
  c.restore();
}

/// White beacon tower behind the right corner of the boathouse.
void _tower(Canvas c) {
  const body = Rect.fromLTRB(54, -118, 92, -6);
  c.drawRect(body, fillPaint(0xFFF2EBDD));
  c.save();
  c.clipRect(body);
  for (final y in [-92.0, -48.0]) {
    c.drawRect(Rect.fromLTRB(54, y, 92, y + 12), fillPaint(0xFFD9473A));
  }
  c.drawRect(const Rect.fromLTRB(80, -118, 92, -6), fillPaint(0x22000000));
  c.restore();
  c.drawRect(body, strokePaint(_ink, 2.2));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(66, -74, 12, 16), const Radius.circular(6)),
      fillPaint(0xFFFFE6A8));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(66, -74, 12, 16), const Radius.circular(6)),
      strokePaint(_ink, 1.6));
  // Lamp room, cap and a pennant.
  c.drawRect(const Rect.fromLTRB(50, -122, 96, -116), fillPaint(0xFF2F5E63));
  c.drawCircle(const Offset(73, -132), 20, fillPaint(0x33FFE08A));
  c.drawRect(const Rect.fromLTRB(60, -142, 86, -122), fillPaint(0xFFFFE08A));
  for (final x in [68.0, 78.0]) {
    c.drawLine(Offset(x, -142), Offset(x, -122), strokePaint(0xFF2F5E63, 2));
  }
  c.drawRect(const Rect.fromLTRB(60, -142, 86, -122), strokePaint(_ink, 1.8));
  c.drawPath(
      Path()
        ..moveTo(56, -142)
        ..lineTo(73, -158)
        ..lineTo(90, -142)
        ..close(),
      fillPaint(0xFF4F8E93));
  c.drawPath(
      Path()
        ..moveTo(56, -142)
        ..lineTo(73, -158)
        ..lineTo(90, -142)
        ..close(),
      strokePaint(_ink, 1.8));
  c.drawLine(const Offset(73, -158), const Offset(73, -176),
      strokePaint(0xFF6E4A2A, 2));
  c.drawPath(
      Path()
        ..moveTo(73, -176)
        ..quadraticBezierTo(84, -173, 92, -170)
        ..quadraticBezierTo(84, -168, 73, -166)
        ..close(),
      fillPaint(0xFFE25D4A));
}

void _lantern(Canvas c, Offset p) {
  c.drawCircle(p + const Offset(0, 6), 11, fillPaint(0x33FFD27A));
  c.drawLine(p + const Offset(0, -6), p, strokePaint(0xFF3B2C21, 1.4));
  final glass = RRect.fromRectAndRadius(
      Rect.fromCenter(center: p + const Offset(0, 6), width: 9, height: 11),
      const Radius.circular(2));
  c.drawRRect(glass, fillPaint(0xFFFFD27A));
  c.drawRRect(glass, strokePaint(0xFF3B2C21, 1.4));
  c.drawLine(p + const Offset(-5, 0), p + const Offset(5, 0),
      strokePaint(0xFF3B2C21, 2));
}

void _anchor(Canvas c, Offset p, double s, int color) {
  final pen = strokePaint(color, s * .32);
  c.drawCircle(p + Offset(0, -s), s * .3, pen);
  c.drawLine(p + Offset(0, -s * .7), p + Offset(0, s), pen);
  c.drawLine(
      p + Offset(-s * .55, -s * .35), p + Offset(s * .55, -s * .35), pen);
  c.drawArc(Rect.fromCircle(center: p + Offset(0, s * .1), radius: s * .9), .35,
      math.pi - .7, false, pen);
}

void _crate(Canvas c, Offset bottomCentre, double s) {
  final r = Rect.fromLTWH(bottomCentre.dx - s / 2, bottomCentre.dy - s, s, s);
  c.drawRect(r, fillPaint(0xFFC08A4E));
  c.drawLine(r.topLeft, r.bottomRight, strokePaint(0xFF8A5A33, 2));
  c.drawLine(r.bottomLeft, r.topRight, strokePaint(0xFF8A5A33, 2));
  c.drawRect(r.deflate(1.5), strokePaint(0xFF8A5A33, 2));
  c.drawRect(r, strokePaint(_ink, 1.6));
}

void _barrel(Canvas c, Offset bottomCentre) {
  final r = Rect.fromCenter(
      center: bottomCentre + const Offset(0, -11), width: 18, height: 22);
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)),
      fillPaint(0xFFA8703F));
  for (final y in [-17.0, -5.0]) {
    c.drawLine(bottomCentre + Offset(-9, y), bottomCentre + Offset(9, y),
        strokePaint(0xFF5E5466, 2));
  }
  c.drawOval(
      Rect.fromCenter(
          center: bottomCentre + const Offset(0, -22), width: 16, height: 5),
      fillPaint(0xFFC79563));
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)),
      strokePaint(_ink, 1.6));
}

void _rope(Canvas c, Offset p) {
  for (var k = 0; k < 3; k++) {
    c.drawOval(
        Rect.fromCenter(center: p, width: 22 - k * 6.0, height: 9 - k * 2.5),
        strokePaint(0xFFC9A46A, 2.6));
  }
  c.drawOval(Rect.fromCenter(center: p, width: 24, height: 11),
      strokePaint(0x888A6A3E, 1));
}

void _bollard(Canvas c, Offset p) {
  c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 9, height: 12),
          const Radius.circular(3)),
      fillPaint(0xFF3E3A40));
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, -6), width: 13, height: 5),
      fillPaint(0xFF56505A));
}

/// Harbour bits around the starting pier at [FishingRiver.startDockX]:
/// a lamp post, bollards with rope, and cargo waiting to be loaded.
void paintHarbourPier(Canvas c) {
  const x = FishingRiver.startDockX;
  final p = Offset(x, FishingRiver.bottom(x) - 15);
  // Lamp post on the land end of the pier.
  final post = p + const Offset(40, 62);
  c.drawLine(post, post + const Offset(0, -64), strokePaint(0xFF3E3A40, 3.5));
  c.drawLine(post + const Offset(0, -60), post + const Offset(10, -60),
      strokePaint(0xFF3E3A40, 2.5));
  _lantern(c, post + const Offset(10, -60));
  // Bollards with a rope out to the water.
  for (final o in const [Offset(-18, 4), Offset(18, 4), Offset(18, 34)]) {
    _bollard(c, p + o);
  }
  c.drawPath(
      Path()
        ..moveTo(p.dx + 18, p.dy + 2)
        ..quadraticBezierTo(p.dx + 34, p.dy - 6, p.dx + 46, p.dy - 22),
      strokePaint(0xFFC9A46A, 1.8));
  // Cargo next to the pier.
  _crate(c, p + const Offset(62, 70), 16);
  _crate(c, p + const Offset(78, 70), 13);
  _barrel(c, p + const Offset(66, 52));
  _rope(c, p + const Offset(-14, 52));
}
