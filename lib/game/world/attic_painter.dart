import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_map.dart';

/// Chapter 5 attic in the 1000x500 design space. It is drawn in normal
/// colours; the darkness layer and moonbeams decide what is visible. The
/// trunk and the rocking chair are [ShelterMap.attic] obstacles.
class AtticPainter extends CustomPainter {
  const AtticPainter();

  static Paint _p(Color c) => Paint()..color = c;
  static void _box(Canvas c, Rect r, Color color, [double radius = 0]) =>
      c.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(radius)), _p(color));
  static Rect _px(Rect r) =>
      Rect.fromLTWH(r.left * 1000, r.top * 500, r.width * 1000, r.height * 500);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    _roof(canvas);
    _floor(canvas);
    final obstacles = ShelterMap.attic.obstacles.map(_px).toList();
    _trunk(canvas, obstacles[0]);
    _chair(canvas, obstacles[1]);
    _clutter(canvas);
    canvas.restore();
  }

  void _roof(Canvas c) {
    // Sloped plank roof meeting at a round window in the gable.
    _box(c, const Rect.fromLTWH(0, 0, 1000, 130), const Color(0xFF8C6B55));
    for (var i = 0; i < 16; i++) {
      final x = i * 70.0;
      c.drawLine(
          Offset(470 + (x - 470) * .2, 0),
          Offset(x - 40, 130),
          Paint()
            ..color = const Color(0xFF6E5241)
            ..strokeWidth = 3);
    }
    for (final (a, b) in [
      (const Offset(0, 120), const Offset(470, 6)),
      (const Offset(1000, 120), const Offset(470, 6)),
    ]) {
      c.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFF5A4031)
            ..strokeWidth = 14);
    }
    final window = Offset(ShelterMap.attic.moonWindow.dx * 1000,
        ShelterMap.attic.moonWindow.dy * 500 + 6);
    c.drawCircle(window, 38, _p(const Color(0xFF5A4031)));
    c.drawCircle(window, 31, _p(const Color(0xFF2B3B66)));
    c.drawCircle(window + const Offset(8, -6), 11, _p(const Color(0xFFF6F1D6)));
    c.drawCircle(window + const Offset(13, -9), 9, _p(const Color(0xFF2B3B66)));
    final random = math.Random(3);
    for (var i = 0; i < 7; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final d = random.nextDouble() * 26;
      c.drawCircle(window + Offset(math.cos(a) * d, math.sin(a) * d), 1.2,
          _p(const Color(0xFFFFF7D6)));
    }
    for (final d in [0.0, math.pi / 2]) {
      c.drawLine(
          window + Offset.fromDirection(d, 31),
          window - Offset.fromDirection(d, 31),
          Paint()
            ..color = const Color(0xFF5A4031)
            ..strokeWidth = 4);
    }
    // Cobwebs in the corners.
    for (final (corner, dir) in [
      (const Offset(0, 0), 1.0),
      (const Offset(1000, 0), -1.0)
    ]) {
      final web = Paint()
        ..color = const Color(0x88F2EEE6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var r = 20.0; r <= 60; r += 20) {
        c.drawArc(Rect.fromCircle(center: corner, radius: r),
            dir > 0 ? 0 : math.pi / 2, math.pi / 2, false, web);
      }
      for (var k = 0; k < 4; k++) {
        final a = (dir > 0 ? 0 : math.pi / 2) + k * math.pi / 6;
        c.drawLine(corner, corner + Offset.fromDirection(a, 64), web);
      }
    }
    c.drawRect(
        const Rect.fromLTWH(0, 124, 1000, 8), _p(const Color(0xFF5A4031)));
  }

  void _floor(Canvas c) {
    _box(c, const Rect.fromLTWH(0, 130, 1000, 370), const Color(0xFFA9825F));
    final seam = Paint()
      ..color = const Color(0x664A3424)
      ..strokeWidth = 1.5;
    final grain = math.Random(21);
    for (var y = 130.0, row = 0; y < 500; y += 28, row++) {
      c.drawRect(
          Rect.fromLTWH(0, y, 1000, 28),
          _p(Color.lerp(const Color(0xFFA9825F), const Color(0xFF93704F),
              grain.nextDouble() * .7)!));
      c.drawLine(Offset(0, y), Offset(1000, y), seam);
      for (var x = row.isEven ? 0.0 : 90.0; x < 1000; x += 180) {
        c.drawLine(Offset(x, y), Offset(x, y + 28), seam);
        c.drawCircle(Offset(x + 8, y + 14), 1.4, _p(const Color(0xFF4A3424)));
      }
    }
    // Dust specks.
    for (var i = 0; i < 60; i++) {
      c.drawCircle(
          Offset(grain.nextDouble() * 1000, 140 + grain.nextDouble() * 350),
          1,
          _p(const Color(0x33F2EEE6)));
    }
  }

  void _shadow(Canvas c, Rect r) => c.drawOval(
      Rect.fromLTWH(r.left - 6, r.bottom - 10, r.width + 12, 20),
      _p(const Color(0x44201510)));

  void _trunk(Canvas c, Rect r) {
    _shadow(c, r);
    _box(c, r, const Color(0xFF7A4B33), 6);
    _box(c, Rect.fromLTWH(r.left, r.top, r.width, r.height * .35),
        const Color(0xFF8E5A3D), 6);
    for (final x in [r.left + 14, r.right - 20]) {
      _box(c, Rect.fromLTWH(x, r.top, 6, r.height), const Color(0xFFC9A04F), 2);
    }
    _box(c, Rect.fromCenter(center: r.center, width: 16, height: 14),
        const Color(0xFFC9A04F), 3);
    c.drawCircle(r.center + const Offset(0, 2), 2, _p(const Color(0xFF3A2A20)));
  }

  void _chair(Canvas c, Rect r) {
    _shadow(c, r);
    final wood = Paint()
      ..color = const Color(0xFF6E4A33)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(
        Offset(r.left + 6, r.top - 20), Offset(r.left + 8, r.bottom - 8), wood);
    c.drawLine(Offset(r.right - 6, r.top - 20),
        Offset(r.right - 8, r.bottom - 8), wood);
    _box(c, Rect.fromLTWH(r.left, r.top + r.height * .35, r.width, 10),
        const Color(0xFF8E5A3D), 3);
    c.drawArc(
        Rect.fromLTWH(r.left - 8, r.bottom - 22, r.width + 16, 24),
        .2,
        math.pi - .4,
        false,
        Paint()
          ..color = const Color(0xFF6E4A33)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    _box(c, Rect.fromLTWH(r.left + 4, r.top - 6, r.width - 8, 20),
        const Color(0xFF9B87C9), 6);
  }

  void _clutter(Canvas c) {
    // Old boxes, a lamp without a bulb and a dusty mirror (decoration only).
    for (final (x, y, w, h) in [
      (60.0, 380.0, 70.0, 50.0),
      (100.0, 340.0, 50.0, 40.0),
      (880.0, 400.0, 80.0, 60.0),
    ]) {
      _box(c, Rect.fromLTWH(x, y, w, h), const Color(0xFFB98F5C), 3);
      c.drawLine(
          Offset(x, y + h * .3),
          Offset(x + w, y + h * .3),
          Paint()
            ..color = const Color(0xFF8A6446)
            ..strokeWidth = 2);
    }
    _box(
        c, const Rect.fromLTWH(900, 170, 40, 110), const Color(0xFF6E4A33), 18);
    _box(c, const Rect.fromLTWH(906, 178, 28, 94), const Color(0xFF8FA5B8), 14);
    c.drawLine(
        const Offset(912, 190),
        const Offset(926, 210),
        Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
