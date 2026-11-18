import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_map.dart';

/// Chapter 4 playroom in the 1000x500 design space. The toy chest and the
/// play tent are the map's obstacles, drawn from [ShelterMap.playroom].
class PlayroomPainter extends CustomPainter {
  const PlayroomPainter();

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
    _floor(canvas);
    final obstacles = ShelterMap.playroom.obstacles.map(_px).toList();
    _chest(canvas, obstacles[0]);
    _tent(canvas, obstacles[1]);
    _clutter(canvas);
    canvas.restore();
  }

  void _wall(Canvas c) {
    // Mint wallpaper with stars, a shelf of toys and paper bunting.
    _box(c, const Rect.fromLTWH(0, 0, 1000, 122), const Color(0xFFCFE8DF));
    final random = math.Random(4);
    for (var i = 0; i < 40; i++) {
      final p =
          Offset(random.nextDouble() * 1000, 10 + random.nextDouble() * 70);
      _star(c, p, 4, const Color(0x66FFFFFF));
    }
    final bunting = Path()..moveTo(0, 14);
    for (var x = 0.0; x <= 1000; x += 100) {
      bunting.quadraticBezierTo(x + 50, 30, x + 100, 14);
    }
    c.drawPath(
        bunting,
        Paint()
          ..color = const Color(0xFF9A7B5E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    const flags = [
      Color(0xFFF2A3B3),
      Color(0xFFFFD36B),
      Color(0xFF8CB0D8),
      Color(0xFFA6D49A)
    ];
    for (var i = 0; i < 20; i++) {
      final x = 15 + i * 50.0;
      final y = 18 + math.sin((x % 100) / 100 * math.pi) * 8;
      c.drawPath(
          Path()
            ..moveTo(x - 9, y)
            ..lineTo(x + 9, y)
            ..lineTo(x, y + 16)
            ..close(),
          _p(flags[i % flags.length]));
    }
    // Toy shelf.
    _box(c, const Rect.fromLTWH(380, 58, 240, 8), const Color(0xFFB27A3E), 2);
    _box(c, const Rect.fromLTWH(394, 36, 22, 22), const Color(0xFFE88F86), 3);
    _box(c, const Rect.fromLTWH(420, 42, 22, 16), const Color(0xFF8CB0D8), 3);
    c.drawCircle(const Offset(468, 46), 12, _p(const Color(0xFFFFD36B)));
    _box(c, const Rect.fromLTWH(500, 28, 18, 30), const Color(0xFFA6D49A), 4);
    c.drawCircle(const Offset(509, 24), 9, _p(const Color(0xFFA6D49A)));
    _box(c, const Rect.fromLTWH(540, 40, 60, 18), const Color(0xFFE9A13A), 4);
    for (final x in [552.0, 588.0]) {
      c.drawCircle(Offset(x, 58), 6, _p(const Color(0xFF4F5560)));
    }
    // Window with a sunny sky and a cat tree in the corner.
    const window = Rect.fromLTWH(120, 30, 110, 70);
    _box(c, window.inflate(6), const Color(0xFFFFFFFF), 6);
    c.drawRect(window, _p(const Color(0xFFBDE4F0)));
    c.drawCircle(const Offset(200, 52), 12, _p(const Color(0xCCFFE7A0)));
    c.drawRect(
        const Rect.fromLTWH(173, 30, 4, 70), _p(const Color(0xFFFFFFFF)));
    _box(c, const Rect.fromLTWH(820, 24, 16, 98), const Color(0xFFD9B98A), 3);
    for (final (x, y) in [(790.0, 30.0), (836.0, 64.0)]) {
      _box(c, Rect.fromLTWH(x, y, 46, 12), const Color(0xFF9B87C9), 5);
    }
    c.drawRect(
        const Rect.fromLTWH(0, 112, 1000, 10), _p(const Color(0xFFB9DCCF)));
  }

  void _floor(Canvas c) {
    // Soft wood floor with a big round rug and a hopscotch mat.
    _box(c, const Rect.fromLTWH(0, 122, 1000, 378), const Color(0xFFE6C8A0));
    final seam = Paint()
      ..color = const Color(0x55A97C4E)
      ..strokeWidth = 1.2;
    for (var y = 122.0, row = 0; y < 500; y += 26, row++) {
      c.drawLine(Offset(0, y), Offset(1000, y), seam);
      for (var x = row.isEven ? 0.0 : 80.0; x < 1000; x += 160) {
        c.drawLine(Offset(x, y), Offset(x, y + 26), seam);
      }
    }
    const rug = Rect.fromLTWH(250, 230, 500, 200);
    c.drawOval(rug.inflate(10), _p(const Color(0xFF9B87C9)));
    c.drawOval(rug, _p(const Color(0xFFC6B6E6)));
    c.drawOval(
        rug.deflate(28),
        Paint()
          ..color = const Color(0xFFF7F0FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      _star(c, rug.center + Offset(math.cos(a) * 200, math.sin(a) * 76), 6,
          const Color(0xFFFFE7A0));
    }
    // Hopscotch squares near the bottom edge.
    const colors = [Color(0xFFF2A3B3), Color(0xFF8CB0D8), Color(0xFFA6D49A)];
    for (var i = 0; i < 5; i++) {
      _box(c, Rect.fromLTWH(420 + i * 34.0, 452, 30, 30),
          colors[i % colors.length].withValues(alpha: .7), 4);
    }
  }

  void _shadow(Canvas c, Rect r) => c.drawOval(
      Rect.fromLTWH(r.left - 6, r.bottom - 10, r.width + 12, 20),
      _p(const Color(0x33402A14)));

  void _chest(Canvas c, Rect r) {
    _shadow(c, r);
    _box(c, r, const Color(0xFFE9A13A), 8);
    _box(c, Rect.fromLTWH(r.left - 4, r.top - 6, r.width + 8, 16),
        const Color(0xFFD08A2B), 6);
    for (final x in [r.left + 18, r.right - 22]) {
      _box(c, Rect.fromLTWH(x, r.top, 6, r.height), const Color(0xFFB9742A), 2);
    }
    // Toys spilling out of the lid.
    c.drawCircle(
        Offset(r.left + 40, r.top - 10), 11, _p(const Color(0xFF8CB0D8)));
    _box(c, Rect.fromLTWH(r.left + 60, r.top - 22, 16, 16),
        const Color(0xFFA6D49A), 3);
    c.drawCircle(
        Offset(r.right - 46, r.top - 12), 9, _p(const Color(0xFFE77FA0)));
    _star(c, Offset(r.center.dx, r.center.dy + 6), 9, const Color(0xFFFFF4DA));
  }

  void _tent(Canvas c, Rect r) {
    _shadow(c, r);
    final tent = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.center.dx, r.top - 18)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(tent, _p(const Color(0xFFF2A3B3)));
    c.drawPath(
        Path()
          ..moveTo(r.center.dx - 12, r.bottom)
          ..lineTo(r.center.dx, r.center.dy - 4)
          ..lineTo(r.center.dx + 12, r.bottom)
          ..close(),
        _p(const Color(0xFF8A4E62)));
    c.drawLine(
        Offset(r.center.dx, r.top - 18),
        Offset(r.center.dx, r.top - 32),
        Paint()
          ..color = const Color(0xFF8A4E62)
          ..strokeWidth = 2);
    c.drawPath(
        Path()
          ..moveTo(r.center.dx, r.top - 32)
          ..lineTo(r.center.dx + 14, r.top - 27)
          ..lineTo(r.center.dx, r.top - 22)
          ..close(),
        _p(const Color(0xFFFFD36B)));
  }

  void _clutter(Canvas c) {
    // Blocks and a toy mouse lying around (decoration only).
    for (final (x, y, color) in [
      (90.0, 440.0, const Color(0xFF8CB0D8)),
      (112.0, 452.0, const Color(0xFFF2A3B3)),
      (880.0, 300.0, const Color(0xFFA6D49A)),
    ]) {
      _box(c, Rect.fromLTWH(x, y, 20, 20), color, 3);
    }
    c.drawOval(
        const Rect.fromLTWH(860, 440, 30, 16), _p(const Color(0xFFBCC5CC)));
    c.drawCircle(const Offset(866, 442), 5, _p(const Color(0xFFE8B4BE)));
    c.drawLine(
        const Offset(890, 450),
        const Offset(910, 460),
        Paint()
          ..color = const Color(0xFF8A939B)
          ..strokeWidth = 1.5);
  }

  void _star(Canvas c, Offset p, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final d = i.isEven ? r : r * .45;
      final q = p + Offset(math.cos(a) * d, math.sin(a) * d);
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    c.drawPath(path..close(), _p(color));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
