import 'dart:math' as math;
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

// White swan pedal boat, head to the right: blue pontoon, a low white tub
// (the cat shows from the belly up, like in the basket boat), a canopy on
// two posts, rainbow-feather wing low on the side and a tall swan neck with
// a red comb and beak.

const _white = 0xFFFDFDFB, _whiteShade = 0xFFDCE3EA, _outline = 0xFF7D8C9C;
const _blue = 0xFF2F62C4, _blueDark = 0xFF1F428A;

final _tub = Path()
  ..moveTo(-60, -12)
  ..quadraticBezierTo(-63, -2, -58, 4)
  ..lineTo(38, 4)
  ..quadraticBezierTo(48, 2, 50, -6)
  ..lineTo(47, -10)
  ..lineTo(-56, -10)
  ..close();

void paintSwanBoatBack(Canvas c) {
  c.drawOval(const Rect.fromLTWH(-68, 8, 134, 28), fillPaint(0x40345A5C));
  c.drawOval(const Rect.fromLTWH(-66, 10, 130, 24), strokePaint(0x88E9FFF7, 2));
  // Canopy: rear post and the curved roof, behind the cat.
  c.drawLine(
      const Offset(-52, -12), const Offset(-50, -98), strokePaint(_outline, 6));
  c.drawLine(
      const Offset(-52, -12), const Offset(-50, -98), strokePaint(_white, 4));
  final roof = Path()
    ..moveTo(-62, -96)
    ..quadraticBezierTo(-60, -110, -40, -112)
    ..lineTo(12, -112)
    ..quadraticBezierTo(26, -110, 28, -98)
    ..lineTo(28, -93)
    ..lineTo(-62, -93)
    ..close();
  c.drawPath(roof, fillPaint(_white));
  c.drawRect(const Rect.fromLTRB(-62, -97, 28, -93), fillPaint(_whiteShade));
  c.drawPath(roof, strokePaint(_outline, 1.6));
  // Inside of the tub: far rim and the blue seat behind the cat.
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-58, -18, 46, -6), const Radius.circular(6)),
      fillPaint(_whiteShade));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-42, -15, 30, -8), const Radius.circular(4)),
      fillPaint(0xFF3A74D8));
  // Two seat backs: the driver's at the boat point, a passenger's behind.
  for (final x in [-46.0, 0.0]) {
    final back = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 13, -32, x + 13, -12), const Radius.circular(7));
    c.drawRRect(back, fillPaint(0xFF2F62C4));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(x - 10, -30, x + 10, -24), const Radius.circular(4)),
        fillPaint(0xFF5B8FE6));
    c.drawRRect(back, strokePaint(0xFF183570, 1.2));
  }
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-58, -18, 46, -6), const Radius.circular(6)),
      strokePaint(_outline, 1.4));
}

void paintSwanBoatFront(Canvas c) {
  // Blue pontoon base.
  final hull = RRect.fromRectAndCorners(const Rect.fromLTRB(-66, 1, 58, 16),
      topLeft: const Radius.circular(4),
      bottomLeft: const Radius.circular(8),
      topRight: const Radius.circular(4),
      bottomRight: const Radius.circular(12));
  c.drawRRect(hull, fillPaint(_blue));
  c.drawRect(const Rect.fromLTRB(-64, 10, 56, 16), fillPaint(_blueDark));
  c.drawLine(
      const Offset(-60, 4), const Offset(52, 4), strokePaint(0x88A9C8FF, 1.4));
  c.drawRRect(hull, strokePaint(0xFF183570, 1.4));
  // Low white tub wall in front of the cat.
  c.drawPath(
      _tub,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(_white), Color(_whiteShade)])
            .createShader(const Rect.fromLTRB(-64, -12, 50, 4)));
  // Rainbow-feather wing along the low side: blue, yellow, red tip.
  c.save();
  c.clipPath(_tub);
  for (var i = 0; i < 4; i++) {
    final x = -52 + i * 5.0;
    c.drawPath(
        Path()
          ..moveTo(x, -8)
          ..quadraticBezierTo(x + 4, -2, x + 1, 4),
        strokePaint(_blue, 3));
  }
  for (var i = 0; i < 4; i++) {
    final x = -30 + i * 5.0;
    c.drawPath(
        Path()
          ..moveTo(x, -8)
          ..quadraticBezierTo(x + 4, -2, x + 1, 4),
        strokePaint(0xFFF5C21B, 3));
  }
  final wing = Path()
    ..moveTo(-8, -8)
    ..cubicTo(8, -10, 22, -6, 22, 0)
    ..cubicTo(18, 4, 2, 4, -6, 3)
    ..quadraticBezierTo(-2, -2, -8, -8)
    ..close();
  c.drawPath(wing, fillPaint(0xFFE2372E));
  c.drawPath(
      Path()
        ..moveTo(-3, -6)
        ..quadraticBezierTo(10, -6, 18, -1),
      strokePaint(0x66FFFFFF, 1.2));
  c.restore();
  c.drawPath(_tub, strokePaint(_outline, 1.6));
  // Steering lever in front of the driver's seat.
  c.drawLine(
      const Offset(32, -8), const Offset(28, -22), strokePaint(0xFF3A4654, 3));
  c.drawCircle(const Offset(28, -23), 3.6, fillPaint(0xFFE2372E));
  c.drawCircle(const Offset(27, -24), 1.2, fillPaint(0xFFFFB3A8));
  // Front canopy post.
  c.drawLine(
      const Offset(20, -10), const Offset(20, -94), strokePaint(_outline, 5));
  c.drawLine(
      const Offset(20, -10), const Offset(20, -94), strokePaint(_white, 3.2));

  // Tall swan neck: thick where it grows from the bow, tapering up to the
  // head, which bends forward.
  final neck = Path()
    ..moveTo(28, -10)
    ..cubicTo(42, -14, 48, -30, 46, -46)
    ..cubicTo(44, -60, 44, -72, 50, -80)
    ..lineTo(64, -82)
    ..cubicTo(58, -72, 58, -62, 62, -50)
    ..cubicTo(68, -30, 64, -6, 48, 4)
    ..lineTo(32, 4)
    ..close();
  c.drawPath(
      neck,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(_white), Color(_white), Color(_whiteShade)],
                stops: [0, .55, 1])
            .createShader(const Rect.fromLTRB(28, -86, 68, 4)));
  c.drawPath(
      Path()
        ..moveTo(64, -40)
        ..quadraticBezierTo(67, -22, 58, -6),
      strokePaint(0xFFE2372E, 3));
  c.drawPath(neck, strokePaint(_outline, 1.6));
  // Head with a red comb, blue eye and a red beak pointing down-forward.
  const head = Offset(58, -88);
  final comb = Path()
    ..moveTo(48, -94)
    ..quadraticBezierTo(48, -106, 58, -104)
    ..quadraticBezierTo(66, -106, 66, -98)
    ..quadraticBezierTo(60, -96, 56, -94)
    ..close();
  c.drawPath(comb, fillPaint(0xFFE2372E));
  c.drawPath(comb, strokePaint(0xFF9C1F1A, 1));
  final skull = Rect.fromCenter(center: head, width: 26, height: 20);
  c.drawOval(skull, fillPaint(_white));
  c.drawOval(skull, strokePaint(_outline, 1.6));
  final beak = Path()
    ..moveTo(68, -93)
    ..quadraticBezierTo(80, -90, 86, -78)
    ..quadraticBezierTo(76, -79, 67, -84)
    ..close();
  c.drawPath(beak, fillPaint(0xFFE2372E));
  c.drawPath(
      Path()
        ..moveTo(68, -88)
        ..quadraticBezierTo(76, -86, 82, -81),
      strokePaint(0xFF9C1F1A, 1));
  c.drawPath(beak, strokePaint(0xFF9C1F1A, 1.2));
  final eye =
      Rect.fromCenter(center: const Offset(59, -90), width: 10, height: 8);
  c.drawOval(eye, fillPaint(0xFF2F62C4));
  c.drawOval(eye, strokePaint(0xFF183570, 1));
  c.drawCircle(const Offset(60, -90.5), 2.2, fillPaint(0xFF14203A));
  c.drawCircle(const Offset(61, -91.5), .9, fillPaint(0xFFFFFFFF));
}

/// The swan's stern paddle wheel under its white housing, spinning while the
/// boat moves, with a churn of foam behind it. Origin = boat point.
void paintSwanPaddleWheel(Canvas c, double clock,
    {required bool moving, required bool facingRight}) {
  c.save();
  if (!facingRight) c.scale(-1, 1);
  const hub = Offset(-68, 3);
  final spin = moving ? clock * 7 : 0.0;
  if (moving) {
    for (var i = 0; i < 6; i++) {
      final t = (clock * 2.2 + i / 6) % 1;
      c.drawCircle(
          hub + Offset(-8 - t * 26, 8 - math.sin(t * math.pi) * 9),
          (1 - t) * 3 + 1,
          Paint()..color = Color.fromRGBO(245, 252, 250, (1 - t) * .85));
    }
  }
  final blade = Paint()..color = const Color(0xFF2F62C4);
  for (var i = 0; i < 6; i++) {
    final a = spin + i * math.pi / 3;
    final tip = hub + Offset(math.cos(a), math.sin(a)) * 14;
    c.save();
    c.translate(tip.dx, tip.dy);
    c.rotate(a);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 5, height: 11),
            const Radius.circular(1.5)),
        blade);
    c.restore();
  }
  c.drawCircle(hub, 4, fillPaint(0xFF1F428A));
  // Housing over the top half of the wheel.
  final housing = Path()
    ..addArc(Rect.fromCircle(center: hub, radius: 18), math.pi, math.pi)
    ..close();
  c.drawPath(housing, fillPaint(0xFFFDFDFB));
  c.drawPath(housing, strokePaint(0xFF7D8C9C, 1.4));
  c.drawArc(Rect.fromCircle(center: hub, radius: 13), math.pi * 1.15,
      math.pi * .7, false, strokePaint(0xFFE2372E, 2));
  c.restore();
}
