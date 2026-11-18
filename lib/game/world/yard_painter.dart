import 'dart:math' as math;
import 'package:flutter/rendering.dart';

import 'shelter_garden_painter.dart';
import 'shelter_map.dart';

/// Chapter 1 front yard: the garden lawn with a bamboo drying rack and two
/// straw mats. Hanging fish are drawn live by RackSystem so one can shake.
class YardPainter extends CustomPainter {
  const YardPainter();

  static Paint _p(Color c) => Paint()..color = c;
  static Rect _px(Rect r) =>
      Rect.fromLTWH(r.left * 1000, r.top * 500, r.width * 1000, r.height * 500);

  @override
  void paint(Canvas canvas, Size size) {
    const ShelterGardenPainter().paint(canvas, size);
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    const map = ShelterMap.yard;
    // Packed-earth patch under the rack where the fish land.
    final rack = _px(map.rack!);
    canvas.drawOval(
        Rect.fromLTWH(rack.left - 20, rack.bottom + 10, rack.width + 40, 90),
        _p(const Color(0x55C9A06C)));
    for (final mat in map.napMats) {
      _mat(canvas, _px(mat));
    }
    _rack(canvas, rack, _px(map.obstacles.first));
    canvas.restore();
  }

  void _rack(Canvas c, Rect r, Rect base) {
    final pole = Paint()
      ..color = const Color(0xFFB99A5B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final knot = Paint()
      ..color = const Color(0xFF8C7340)
      ..strokeWidth = 2;
    for (final x in [r.left, r.right]) {
      c.drawLine(Offset(x, r.top - 6), Offset(x, base.bottom), pole);
      for (var y = r.top + 14; y < base.bottom; y += 22) {
        c.drawLine(Offset(x - 4, y), Offset(x + 4, y), knot);
      }
    }
    c.drawLine(Offset(r.left - 10, r.top), Offset(r.right + 10, r.top),
        pole..strokeWidth = 6);
    // Woven basket of dried fish at the foot of the rack (the obstacle).
    final basket = RRect.fromRectAndRadius(base, const Radius.circular(10));
    c.drawOval(
        Rect.fromLTWH(base.left - 6, base.bottom - 8, base.width + 12, 16),
        _p(const Color(0x33402A14)));
    c.drawRRect(basket, _p(const Color(0xFFC08A4E)));
    final weave = Paint()
      ..color = const Color(0xFF9A6A36)
      ..strokeWidth = 1.5;
    for (var x = base.left + 8; x < base.right; x += 12) {
      c.drawLine(
          Offset(x, base.top + 2), Offset(x + 4, base.bottom - 2), weave);
    }
    for (var i = 0; i < 5; i++) {
      final x = base.left + 26 + i * (base.width - 52) / 4;
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x, base.top + 2), width: 30, height: 10),
          _p(const Color(0xFFC98B4E)));
    }
    // A little sign so players read the rack as a food source.
    final sign = Rect.fromLTWH(r.right + 14, r.top + 4, 54, 26);
    c.drawLine(
        Offset(sign.center.dx, sign.bottom),
        Offset(sign.center.dx, base.bottom),
        Paint()
          ..color = const Color(0xFF8C6544)
          ..strokeWidth = 3);
    c.drawRRect(RRect.fromRectAndRadius(sign, const Radius.circular(4)),
        _p(const Color(0xFFF2E3C6)));
    final fish = Path()
      ..moveTo(sign.left + 12, sign.center.dy)
      ..quadraticBezierTo(
          sign.center.dx, sign.top + 4, sign.right - 16, sign.center.dy)
      ..quadraticBezierTo(
          sign.center.dx, sign.bottom - 4, sign.left + 12, sign.center.dy)
      ..moveTo(sign.right - 16, sign.center.dy)
      ..lineTo(sign.right - 8, sign.top + 7)
      ..lineTo(sign.right - 8, sign.bottom - 7)
      ..close();
    c.drawPath(fish, _p(const Color(0xFFC98B4E)));
  }

  void _mat(Canvas c, Rect r) {
    c.drawOval(r.shift(const Offset(0, 6)), _p(const Color(0x33402A14)));
    c.drawOval(r, _p(const Color(0xFFE6C05A)));
    final straw = Paint()
      ..color = const Color(0xFFCFA43F)
      ..strokeWidth = 1.4;
    final random = math.Random(r.left.toInt());
    for (var i = 0; i < 26; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final d = random.nextDouble() * .42;
      final p = r.center +
          Offset(math.cos(a) * r.width * d, math.sin(a) * r.height * d);
      c.drawLine(p, p + Offset.fromDirection(a + 1.2, 9), straw);
    }
    c.drawOval(
        r.deflate(8),
        Paint()
          ..color = const Color(0xFFF7DE86)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
