import 'package:flutter/painting.dart';

import '../../fishing/fishing_boat.dart';
import 'fishing_art_kit.dart';
import 'fishing_boat_art.dart';
import 'fishing_river_scene.dart';

/// Part of [boat] drawn under the cat (origin = boat point). Only the swan
/// has a head, so only it turns with [facingRight].
void paintBoatBack(Canvas c, FishingBoat boat, {bool facingRight = true}) =>
    switch (boat) {
      FishingBoat.basket => paintBasketBoatBack(c),
      FishingBoat.paper => paintPaperBoatBack(c),
      FishingBoat.swan => _facing(c, facingRight, paintSwanBoatBack),
    };

/// Part of [boat] drawn over the cat, so the cat sits inside.
void paintBoatFront(Canvas c, FishingBoat boat, {bool facingRight = true}) =>
    switch (boat) {
      FishingBoat.basket => paintBasketBoatFront(c),
      FishingBoat.paper => paintPaperBoatFront(c),
      FishingBoat.swan => _facing(c, facingRight, paintSwanBoatFront),
    };

void _facing(Canvas c, bool right, void Function(Canvas) draw) {
  if (right) return draw(c);
  c.save();
  c.scale(-1, 1);
  draw(c);
  c.restore();
}

// White swan pedal boat, head to the right: blue pontoon, white tub with a
// blue seat, a canopy on two posts, rainbow-feather wing on the side and a
// tall S-shaped neck with a red crest and beak.

const _white = 0xFFFDFDFB, _whiteShade = 0xFFDCE3EA, _outline = 0xFF7D8C9C;
const _blue = 0xFF2F62C4, _blueDark = 0xFF1F428A;

final _tub = Path()
  ..moveTo(-60, -30)
  ..quadraticBezierTo(-64, -12, -58, 2)
  ..lineTo(36, 2)
  ..quadraticBezierTo(48, 0, 50, -12)
  ..lineTo(46, -26)
  ..lineTo(-56, -26)
  ..close();

void paintSwanBoatBack(Canvas c) {
  c.drawOval(const Rect.fromLTWH(-68, 6, 134, 28), fillPaint(0x40345A5C));
  c.drawOval(const Rect.fromLTWH(-66, 8, 130, 24), strokePaint(0x88E9FFF7, 2));
  // Canopy: rear post and the curved roof, behind the cat.
  c.drawLine(const Offset(-52, -26), const Offset(-50, -102),
      strokePaint(_outline, 6));
  c.drawLine(
      const Offset(-52, -26), const Offset(-50, -102), strokePaint(_white, 4));
  final roof = Path()
    ..moveTo(-62, -100)
    ..quadraticBezierTo(-60, -114, -40, -116)
    ..lineTo(14, -116)
    ..quadraticBezierTo(26, -114, 28, -102)
    ..lineTo(28, -97)
    ..lineTo(-62, -97)
    ..close();
  c.drawPath(roof, fillPaint(_white));
  c.drawRect(const Rect.fromLTRB(-62, -101, 28, -97), fillPaint(_whiteShade));
  c.drawPath(roof, strokePaint(_outline, 1.6));
  // Inside of the tub: back rest and the blue seat.
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-56, -34, 44, -22), const Radius.circular(6)),
      fillPaint(_whiteShade));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-40, -31, 28, -24), const Radius.circular(4)),
      fillPaint(0xFF3A74D8));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-56, -34, 44, -22), const Radius.circular(6)),
      strokePaint(_outline, 1.4));
}

void paintSwanBoatFront(Canvas c) {
  // Blue pontoon base.
  final hull = RRect.fromRectAndCorners(const Rect.fromLTRB(-66, -2, 58, 14),
      topLeft: const Radius.circular(4),
      bottomLeft: const Radius.circular(8),
      topRight: const Radius.circular(4),
      bottomRight: const Radius.circular(12));
  c.drawRRect(hull, fillPaint(_blue));
  c.drawRect(const Rect.fromLTRB(-64, 8, 56, 14), fillPaint(_blueDark));
  c.drawLine(
      const Offset(-60, 1), const Offset(52, 1), strokePaint(0x88A9C8FF, 1.4));
  c.drawRRect(hull, strokePaint(0xFF183570, 1.4));
  // White tub wall in front of the cat.
  c.drawPath(
      _tub,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(_white), Color(_whiteShade)])
            .createShader(const Rect.fromLTRB(-64, -30, 50, 2)));
  // Rainbow-feather wing: blue, yellow, then the red wing tip.
  c.save();
  c.clipPath(_tub);
  for (var i = 0; i < 4; i++) {
    final x = -52 + i * 5.5;
    c.drawPath(
        Path()
          ..moveTo(x, -22)
          ..quadraticBezierTo(x + 6, -12, x + 2, 0),
        strokePaint(_blue, 3.4));
  }
  for (var i = 0; i < 4; i++) {
    final x = -28 + i * 5.5;
    c.drawPath(
        Path()
          ..moveTo(x, -22)
          ..quadraticBezierTo(x + 6, -12, x + 2, 0),
        strokePaint(0xFFF5C21B, 3.4));
  }
  final wing = Path()
    ..moveTo(-4, -22)
    ..cubicTo(14, -24, 26, -16, 24, -4)
    ..cubicTo(20, 0, 4, 0, -2, -2)
    ..quadraticBezierTo(4, -12, -4, -22)
    ..close();
  c.drawPath(wing, fillPaint(0xFFE2372E));
  c.drawPath(
      Path()
        ..moveTo(0, -18)
        ..quadraticBezierTo(14, -18, 20, -8),
      strokePaint(0x66FFFFFF, 1.2));
  c.restore();
  c.drawPath(_tub, strokePaint(_outline, 1.6));
  // Front canopy post.
  c.drawLine(
      const Offset(26, -24), const Offset(26, -98), strokePaint(_outline, 5.5));
  c.drawLine(
      const Offset(26, -24), const Offset(26, -98), strokePaint(_white, 3.6));

  // Tall swan neck: thick where it grows from the bow, tapering up to the
  // head, which bends forward.
  final neck = Path()
    ..moveTo(26, -24)
    ..cubicTo(40, -26, 48, -40, 46, -56)
    ..cubicTo(44, -70, 44, -82, 50, -90)
    ..lineTo(64, -92)
    ..cubicTo(58, -82, 58, -72, 62, -60)
    ..cubicTo(68, -40, 66, -14, 48, 2)
    ..lineTo(30, 2)
    ..close();
  c.drawPath(
      neck,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(_white), Color(_white), Color(_whiteShade)],
                stops: [0, .55, 1])
            .createShader(const Rect.fromLTRB(26, -96, 68, 2)));
  // Red trim down the breast, like the painted pedal boats.
  c.drawPath(
      Path()
        ..moveTo(64, -50)
        ..quadraticBezierTo(68, -30, 58, -12),
      strokePaint(0xFFE2372E, 3));
  c.drawPath(neck, strokePaint(_outline, 1.6));
  // Head with a red comb, blue eye and a red beak pointing down-forward.
  const head = Offset(58, -98);
  final comb = Path()
    ..moveTo(48, -104)
    ..quadraticBezierTo(48, -116, 58, -114)
    ..quadraticBezierTo(66, -116, 66, -108)
    ..quadraticBezierTo(60, -106, 56, -104)
    ..close();
  c.drawPath(comb, fillPaint(0xFFE2372E));
  c.drawPath(comb, strokePaint(0xFF9C1F1A, 1));
  final skull = Rect.fromCenter(center: head, width: 26, height: 20);
  c.drawOval(skull, fillPaint(_white));
  c.drawOval(skull, strokePaint(_outline, 1.6));
  final beak = Path()
    ..moveTo(68, -103)
    ..quadraticBezierTo(80, -100, 86, -88)
    ..quadraticBezierTo(76, -89, 67, -94)
    ..close();
  c.drawPath(beak, fillPaint(0xFFE2372E));
  c.drawPath(
      Path()
        ..moveTo(68, -98)
        ..quadraticBezierTo(76, -96, 82, -91),
      strokePaint(0xFF9C1F1A, 1));
  c.drawPath(beak, strokePaint(0xFF9C1F1A, 1.2));
  c.drawOval(
      Rect.fromCenter(center: const Offset(59, -100), width: 10, height: 8),
      fillPaint(0xFF2F62C4));
  c.drawOval(
      Rect.fromCenter(center: const Offset(59, -100), width: 10, height: 8),
      strokePaint(0xFF183570, 1));
  c.drawCircle(const Offset(60, -100.5), 2.2, fillPaint(0xFF14203A));
  c.drawCircle(const Offset(61, -101.5), .9, fillPaint(0xFFFFFFFF));
}
