import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_map.dart';

/// Chapter 3 kitchen, in the same 1000x500 design space as the other maps.
/// The island and the trolley are the map's obstacles, so they are drawn
/// from [ShelterMap.kitchen] and stay in step with the collision rects.
class KitchenPainter extends CustomPainter {
  const KitchenPainter();

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
    _wall(canvas);
    _counter(canvas);
    _floor(canvas);
    final obstacles = ShelterMap.kitchen.obstacles.map(_px).toList();
    _island(canvas, obstacles[0]);
    _trolley(canvas, obstacles[1]);
    _corner(canvas);
    canvas.restore();
  }

  void _wall(Canvas c) {
    // Cream subway tiles.
    _box(c, const Rect.fromLTWH(0, 0, 1000, 122), const Color(0xFFF5EBD6));
    final grout = _p(const Color(0xFFE3D3B6));
    for (var row = 0; row * 14.0 < 122; row++) {
      final y = row * 14.0;
      c.drawRect(Rect.fromLTWH(0, y, 1000, 1.2), grout);
      for (var x = row.isEven ? 0.0 : 18.0; x < 1000; x += 36) {
        c.drawRect(Rect.fromLTWH(x, y, 1.2, 14), grout);
      }
    }
    // Upper cabinets, window with curtains, range hood.
    for (final x in [40.0, 150.0, 640.0, 750.0]) {
      _box(c, Rect.fromLTWH(x, 6, 96, 44), const Color(0xFF8FB7A5), 4);
      _box(c, Rect.fromLTWH(x + 6, 11, 40, 34), const Color(0xFFA6C8B8), 3);
      _box(c, Rect.fromLTWH(x + 50, 11, 40, 34), const Color(0xFFA6C8B8), 3);
      for (final dx in [41.0, 55.0]) {
        c.drawCircle(Offset(x + dx, 30), 2.2, _p(const Color(0xFFE9C25A)));
      }
    }
    const window = Rect.fromLTWH(300, 10, 130, 66);
    _box(c, window.inflate(6), const Color(0xFFFFFFFF), 4);
    c.drawRect(
        window,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBDE4F0), Color(0xFFEAF6DC)])
              .createShader(window));
    c.drawCircle(const Offset(400, 30), 10, _p(const Color(0xCCFFE7A0)));
    c.drawRect(
        const Rect.fromLTWH(363, 10, 4, 66), _p(const Color(0xFFFFFFFF)));
    for (final (x, dir) in [(294.0, 1.0), (436.0, -1.0)]) {
      c.drawPath(
          Path()
            ..moveTo(x, 4)
            ..lineTo(x + dir * 30, 4)
            ..quadraticBezierTo(x + dir * 14, 40, x + dir * 22, 84)
            ..lineTo(x, 84)
            ..close(),
          _p(const Color(0xFFE88F86)));
    }
    _box(c, const Rect.fromLTWH(290, 0, 152, 6), const Color(0xFFB27A3E), 2);
    // Range hood above the stove.
    c.drawPath(
        Path()
          ..moveTo(500, 0)
          ..lineTo(580, 0)
          ..lineTo(600, 46)
          ..lineTo(480, 46)
          ..close(),
        _p(const Color(0xFFBCC5CC)));
    _box(c, const Rect.fromLTWH(476, 44, 128, 8), const Color(0xFF9AA6AE), 2);
    // Hanging utensils.
    for (var i = 0; i < 4; i++) {
      final x = 870.0 + i * 26;
      c.drawLine(
          Offset(x, 10),
          Offset(x, 40),
          Paint()
            ..color = const Color(0xFF6E5A4A)
            ..strokeWidth = 2);
      if (i.isEven) {
        c.drawCircle(Offset(x, 48), 9, _p(const Color(0xFFB27A3E)));
      } else {
        c.drawOval(
            Rect.fromCenter(center: Offset(x, 48), width: 10, height: 16),
            _p(const Color(0xFF9AA6AE)));
      }
    }
    c.drawLine(
        const Offset(860, 10),
        const Offset(964, 10),
        Paint()
          ..color = const Color(0xFF6E5A4A)
          ..strokeWidth = 3);
  }

  void _counter(Canvas c) {
    // Base cabinets along the wall with stove and sink on the worktop.
    _box(c, const Rect.fromLTWH(0, 84, 1000, 38), const Color(0xFF7FA595));
    for (var x = 0.0; x < 1000; x += 80) {
      _box(c, Rect.fromLTWH(x + 4, 92, 72, 28), const Color(0xFF94BBA9), 3);
      c.drawRect(Rect.fromLTWH(x + 30, 96, 20, 3), _p(const Color(0xFFE9C25A)));
    }
    _box(c, const Rect.fromLTWH(0, 76, 1000, 10), const Color(0xFFD9B98A), 2);
    // Stove with two pots.
    _box(c, const Rect.fromLTWH(482, 70, 116, 8), const Color(0xFF4F5560), 2);
    _box(c, const Rect.fromLTWH(490, 46, 44, 26), const Color(0xFFD9675A), 6);
    _box(c, const Rect.fromLTWH(486, 44, 52, 6), const Color(0xFFB9483E), 3);
    _box(c, const Rect.fromLTWH(548, 54, 40, 18), const Color(0xFF9AA6AE), 5);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(505 + i * 10.0, 36 - i * 6.0), 4 + i * 1.5,
          _p(const Color(0x66FFFFFF)));
    }
    // Sink under the window.
    _box(c, const Rect.fromLTWH(318, 72, 94, 8), const Color(0xFFBCC5CC), 3);
    c.drawLine(
        const Offset(365, 72),
        const Offset(365, 56),
        Paint()
          ..color = const Color(0xFF9AA6AE)
          ..strokeWidth = 4);
    c.drawLine(
        const Offset(365, 56),
        const Offset(380, 56),
        Paint()
          ..color = const Color(0xFF9AA6AE)
          ..strokeWidth = 4);
    // Fish tank of the day on the worktop: the three dishes on display.
    _box(c, const Rect.fromLTWH(690, 60, 120, 18), const Color(0xFFF7F3EA), 6);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
          Offset(712 + i * 38.0, 66),
          9,
          _p([
            const Color(0xFF53C9EF),
            const Color(0xFFF0884A),
            const Color(0xFFF27A6B)
          ][i]));
    }
    // Fridge on the far right.
    _box(c, const Rect.fromLTWH(940, 6, 56, 116), const Color(0xFFF4F7F8), 6);
    c.drawLine(
        const Offset(940, 50),
        const Offset(996, 50),
        Paint()
          ..color = const Color(0xFFC7D0D6)
          ..strokeWidth = 2);
    for (final y in [24.0, 70.0]) {
      c.drawLine(
          Offset(948, y),
          Offset(948, y + 18),
          Paint()
            ..color = const Color(0xFF9AA6AE)
            ..strokeWidth = 3);
    }
    c.drawCircle(const Offset(980, 30), 5, _p(const Color(0xFFE48A87)));
  }

  void _floor(Canvas c) {
    // Warm checkered tiles with a runner rug through the middle.
    _box(c, const Rect.fromLTWH(0, 122, 1000, 378), const Color(0xFFF2E3C6));
    final dark = _p(const Color(0xFFE2B98F));
    for (var y = 122.0, row = 0; y < 500; y += 42, row++) {
      for (var x = row.isEven ? 0.0 : 42.0; x < 1000; x += 84) {
        c.drawRect(Rect.fromLTWH(x, y, 42, 42), dark);
      }
    }
    c.drawRect(
        const Rect.fromLTWH(0, 122, 1000, 8), _p(const Color(0x33402A14)));
    final grain = math.Random(7);
    for (var i = 0; i < 40; i++) {
      c.drawCircle(
          Offset(grain.nextDouble() * 1000, 130 + grain.nextDouble() * 370),
          1,
          _p(const Color(0x22704019)));
    }
  }

  void _shadow(Canvas c, Rect r) => c.drawOval(
      Rect.fromLTWH(r.left - 6, r.bottom - 10, r.width + 12, 20),
      _p(const Color(0x33402A14)));

  void _island(Canvas c, Rect r) {
    _shadow(c, r);
    _box(c, r, const Color(0xFF7FA595), 8);
    _box(c, Rect.fromLTWH(r.left - 6, r.top - 6, r.width + 12, 18),
        const Color(0xFFD9B98A), 6);
    for (var x = r.left + 10; x < r.right - 20; x += 44) {
      _box(c, Rect.fromLTWH(x, r.top + 20, 36, r.height - 26),
          const Color(0xFF94BBA9), 4);
    }
    // Cutting board, knife and a fruit bowl on top.
    _box(c, Rect.fromLTWH(r.left + 14, r.top - 4, 50, 12),
        const Color(0xFFC08A55), 4);
    c.drawLine(
        Offset(r.left + 22, r.top + 2),
        Offset(r.left + 52, r.top + 2),
        Paint()
          ..color = const Color(0xFFCBD3D9)
          ..strokeWidth = 2.5);
    c.drawOval(Rect.fromLTWH(r.right - 70, r.top - 6, 48, 14),
        _p(const Color(0xFFF7F3EA)));
    for (final (dx, color) in [
      (-58.0, const Color(0xFFE0533E)),
      (-46.0, const Color(0xFFF2C437)),
      (-34.0, const Color(0xFF8CB98A)),
    ]) {
      c.drawCircle(Offset(r.right + dx, r.top - 4), 6, _p(color));
    }
  }

  void _trolley(Canvas c, Rect r) {
    _shadow(c, r);
    final frame = Paint()
      ..color = const Color(0xFF8A939B)
      ..strokeWidth = 3;
    for (final x in [r.left + 3, r.right - 3]) {
      c.drawLine(Offset(x, r.top), Offset(x, r.bottom - 4), frame);
    }
    for (final y in [r.top + 4, r.center.dy, r.bottom - 8]) {
      _box(c, Rect.fromLTWH(r.left, y - 3, r.width, 7), const Color(0xFFBCC5CC),
          2);
    }
    // Bowls of fish, shrimp and salmon waiting to be served.
    for (var i = 0; i < 3; i++) {
      c.drawOval(
          Rect.fromLTWH(r.left + 6 + i * (r.width - 12) / 3, r.top - 6,
              (r.width - 16) / 3, 9),
          _p([
            const Color(0xFF53C9EF),
            const Color(0xFFF0884A),
            const Color(0xFFF27A6B)
          ][i]));
    }
    for (final x in [r.left + 6, r.right - 6]) {
      c.drawCircle(Offset(x, r.bottom - 2), 4, _p(const Color(0xFF4F5560)));
    }
  }

  void _corner(Canvas c) {
    // Food bowls and a cat-shaped mat by the beds' side of the room.
    for (final (x, color) in [(40.0, 0xFF53C9EF), (80.0, 0xFFF0884A)]) {
      c.drawOval(Rect.fromLTWH(x, 466, 32, 12), _p(Color(color)));
      c.drawOval(Rect.fromLTWH(x + 4, 466, 24, 6), _p(const Color(0xFFF7F3EA)));
    }
    _box(c, const Rect.fromLTWH(900, 456, 70, 30), const Color(0xFFE88F86), 12);
    for (final dx in [912.0, 958.0]) {
      c.drawPath(
          Path()
            ..moveTo(dx - 6, 458)
            ..lineTo(dx, 446)
            ..lineTo(dx + 6, 458)
            ..close(),
          _p(const Color(0xFFE88F86)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
