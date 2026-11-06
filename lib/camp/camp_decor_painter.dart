import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Detailed art for each camp decoration, drawn in a 60x60 box with the item
/// standing on the bottom edge. Every item has a soft floor shadow, a lit and a
/// shaded side, and a few small details so it reads well at shop-icon size too.
class CampDecorPainter extends CustomPainter {
  const CampDecorPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 60, size.height / 60);
    if (!const {'lantern', 'frames', 'shelf', 'rug'}.contains(id)) {
      canvas.drawOval(const Rect.fromLTWH(6, 50, 48, 9),
          Paint()..color = const Color(0x334B392C));
    }
    switch (id) {
      case 'yarn':
        _yarn(canvas);
      case 'flowers':
        _flowers(canvas);
      case 'bed':
        _bed(canvas);
      case 'post':
        _post(canvas);
      case 'lantern':
        _lantern(canvas);
      case 'bowl':
        _bowl(canvas);
      case 'house':
        _house(canvas);
      case 'sofa':
        _sofa(canvas);
      case 'shelf':
        _shelf(canvas);
      case 'frames':
        _frames(canvas);
      case 'rug':
        _rug(canvas);
      case 'lamp':
        _lamp(canvas);
    }
    canvas.restore();
  }

  Paint _p(int c) => Paint()..color = Color(c);
  Paint _line(int c, double w) => Paint()
    ..color = Color(c)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _yarn(Canvas canvas) {
    const c = Offset(28, 40);
    // Loose thread trailing on the floor.
    canvas.drawPath(
        Path()
          ..moveTo(40, 48)
          ..cubicTo(48, 54, 50, 44, 57, 52),
        _line(0xFFD6727C, 2));
    canvas.drawCircle(c, 14, _p(0xFFE88A95));
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: 14)));
    canvas.drawCircle(c + const Offset(5, 5), 14, _p(0xFFD6727C));
    final wrap = _line(0xFFFFC2C8, 1.6);
    for (var i = -3; i <= 3; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: c + Offset(i * 5.0, 0), radius: 16),
          -1.2,
          2.4,
          false,
          wrap);
    }
    final cross = _line(0xFFC45E69, 1.4);
    for (var i = -2; i <= 2; i++) {
      canvas.drawLine(
          c + Offset(-14, i * 6.0 - 4), c + Offset(14, i * 6.0 + 4), cross);
    }
    canvas.restore();
    canvas.drawCircle(c + const Offset(-5, -6), 3, _p(0x88FFFFFF));
    // Knitting needles stuck in the ball.
    canvas.drawLine(
        const Offset(18, 22), const Offset(34, 36), _line(0xFFB27A3E, 2.2));
    canvas.drawCircle(const Offset(18, 22), 2.2, _p(0xFFFFC24D));
  }

  void _flowers(Canvas canvas) {
    // Leaves and stems first, then a terracotta pot with a rim.
    final stem = _line(0xFF4E8A4A, 2);
    for (final top in const [
      Offset(18, 14),
      Offset(30, 8),
      Offset(42, 15),
      Offset(24, 22),
      Offset(37, 21)
    ]) {
      canvas.drawLine(const Offset(30, 34), top, stem);
    }
    final leaf = _p(0xFF6BA765);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(21, 28), width: 12, height: 6),
        leaf);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(40, 27), width: 12, height: 6),
        leaf);
    for (final (o, petal) in const [
      (Offset(18, 14), 0xFFFF9CA8),
      (Offset(30, 8), 0xFFFFE07A),
      (Offset(42, 15), 0xFFFF9CA8),
      (Offset(24, 22), 0xFFFFFFFF),
      (Offset(37, 21), 0xFFB9A4E8),
    ]) {
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        canvas.drawCircle(
            o + Offset(math.cos(a) * 3.4, math.sin(a) * 3.4), 2.8, _p(petal));
      }
      canvas.drawCircle(o, 2, _p(0xFFE8A93A));
    }
    final pot = Path()
      ..moveTo(17, 36)
      ..lineTo(43, 36)
      ..lineTo(39, 54)
      ..lineTo(21, 54)
      ..close();
    canvas.drawPath(pot, _p(0xFFC9714A));
    canvas.drawPath(
        Path()
          ..moveTo(34, 36)
          ..lineTo(43, 36)
          ..lineTo(39, 54)
          ..lineTo(32, 54)
          ..close(),
        _p(0xFFA95A3A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(15, 33, 30, 6), const Radius.circular(2)),
        _p(0xFFDB8558));
    canvas.drawLine(
        const Offset(21, 46), const Offset(37, 46), _line(0x55FFF4DA, 1.5));
  }

  void _bed(Canvas canvas) {
    // Round bolster bed with a quilted cushion and a paw-print pillow.
    const outer = Rect.fromLTWH(4, 28, 52, 26);
    canvas.drawOval(outer, _p(0xFF8E5A3C));
    canvas.drawOval(
        outer.deflate(2).shift(const Offset(0, -2)), _p(0xFFB0744E));
    const cushion = Rect.fromLTWH(11, 32, 38, 16);
    canvas.drawOval(cushion, _p(0xFFF6D6B4));
    canvas.drawOval(
        cushion.deflate(3).shift(const Offset(0, 2)), _p(0xFFEFC59C));
    final quilt = _line(0x66B0744E, 1);
    for (final x in const [22.0, 30.0, 38.0]) {
      canvas.drawLine(Offset(x, 35), Offset(x, 46), quilt);
    }
    canvas.drawOval(const Rect.fromLTWH(30, 30, 16, 9), _p(0xFFFFF4DA));
    canvas.drawCircle(const Offset(38, 35), 1.8, _p(0xFFE88A95));
    for (final d in const [
      Offset(35.5, 32.8),
      Offset(38, 32),
      Offset(40.5, 32.8)
    ]) {
      canvas.drawCircle(d, .9, _p(0xFFE88A95));
    }
    // Bolster stitching.
    final stitch = _line(0xFFD59A6E, 1.2);
    for (var a = 3.4; a < 6.0; a += .35) {
      final p = Offset(30 + math.cos(a) * 25, 41 + math.sin(a) * 12);
      canvas.drawLine(p, p + const Offset(1.6, 0), stitch);
    }
  }

  void _post(Canvas canvas) {
    // Base, sisal-wrapped column, a top platform and a dangling toy.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 46, 44, 9), const Radius.circular(3)),
        _p(0xFF8C5A34));
    canvas.drawRect(const Rect.fromLTWH(8, 46, 44, 3), _p(0xFFA9714A));
    canvas.drawRect(const Rect.fromLTWH(24, 12, 12, 34), _p(0xFFD9B27A));
    canvas.drawRect(const Rect.fromLTWH(31, 12, 5, 34), _p(0xFFC29A62));
    final rope = _line(0xFFB58A54, 1.3);
    for (var y = 14.0; y < 46; y += 3) {
      canvas.drawLine(Offset(24, y), Offset(36, y + 1.5), rope);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 6, 36, 8), const Radius.circular(3)),
        _p(0xFFE8B4A0));
    canvas.drawRect(const Rect.fromLTWH(12, 6, 36, 3), _p(0xFFF6D4C4));
    canvas.drawLine(
        const Offset(44, 14), const Offset(46, 30), _line(0xFF8C5A34, 1));
    canvas.drawCircle(const Offset(46, 32), 3.5, _p(0xFF7FB3C7));
    canvas.drawCircle(const Offset(45, 31), 1.2, _p(0xAAFFFFFF));
  }

  void _lantern(Canvas canvas) {
    // Hanging red paper lantern with gold caps, ribs, a glow and a tassel.
    canvas.drawLine(
        const Offset(30, 0), const Offset(30, 10), _line(0xFF5A3214, 1.5));
    canvas.drawCircle(const Offset(30, 30), 26, _p(0x33FFD36B));
    final body =
        Rect.fromCenter(center: const Offset(30, 30), width: 34, height: 30);
    canvas.drawOval(body, _p(0xFFD94A3F));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(27, 28), width: 20, height: 20),
        _p(0xFFF06A55));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 30), width: 14, height: 16),
        _p(0x66FFE7A0));
    final rib = _line(0x88A8322B, 1.2);
    for (final dx in const [-11.0, -5.5, 0.0, 5.5, 11.0]) {
      canvas.drawArc(
          Rect.fromCenter(
              center: const Offset(30, 30),
              width: dx.abs() * 2 + .1,
              height: 30),
          dx < 0 ? math.pi / 2 : -math.pi / 2,
          math.pi,
          false,
          rib);
    }
    for (final y in const [12.0, 43.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(22, y, 16, 5), const Radius.circular(2)),
          _p(0xFFE8B23A));
    }
    final tassel = _line(0xFFE8B23A, 1.4);
    for (final dx in const [-2.0, 0.0, 2.0]) {
      canvas.drawLine(Offset(30 + dx, 48), Offset(30 + dx * 1.5, 58), tassel);
    }
  }

  void _bowl(Canvas canvas) {
    // Round glass fishbowl on a small stand, water, a fish, pebbles and bubbles.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 49, 28, 6), const Radius.circular(3)),
        _p(0xFF8C5A34));
    const c = Offset(30, 32);
    final glass = Rect.fromCircle(center: c, radius: 19);
    canvas.drawCircle(c, 19, _p(0x55CDEFF5));
    canvas.save();
    canvas.clipPath(Path()..addOval(glass));
    canvas.drawRect(const Rect.fromLTWH(10, 26, 40, 30), _p(0xAA5FB4D0));
    canvas.drawRect(const Rect.fromLTWH(10, 26, 40, 2), _p(0xCCB8E6F0));
    for (final (o, col) in const [
      (Offset(22, 49), 0xFFC1A27C),
      (Offset(29, 50), 0xFF9AA49A),
      (Offset(36, 49), 0xFFD8B484),
    ]) {
      canvas.drawCircle(o, 3.2, _p(col));
    }
    canvas.drawLine(
        const Offset(37, 50), const Offset(35, 34), _line(0xFF4E8A4A, 2));
    canvas.restore();
    // Goldfish.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(27, 37), width: 13, height: 8),
        _p(0xFFF28A3A));
    canvas.drawPath(
        Path()
          ..moveTo(21, 37)
          ..lineTo(16, 33)
          ..lineTo(16, 41)
          ..close(),
        _p(0xFFF0A050));
    canvas.drawCircle(const Offset(31, 36), 1.1, _p(0xFF3B2415));
    for (final (o, r) in const [(Offset(34, 30), 1.6), (Offset(36, 26), 1.1)]) {
      canvas.drawCircle(o, r, _line(0xCCFFFFFF, .9));
    }
    canvas.drawCircle(c, 19, _line(0x88FFFFFF, 1.5));
    canvas.drawArc(glass.deflate(4), 3.6, .9, false, _line(0xCCFFFFFF, 2));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 14), width: 20, height: 5),
        _line(0x99FFFFFF, 1.5));
  }

  void _house(Canvas canvas) {
    // Wooden cat house: shingled roof, plank walls, arched door, window, sign.
    canvas.drawRect(const Rect.fromLTWH(10, 26, 40, 28), _p(0xFFE7C3A3));
    canvas.drawRect(const Rect.fromLTWH(36, 26, 14, 28), _p(0xFFD6AD88));
    final plank = _line(0x55A9714A, 1);
    for (var y = 31.0; y < 54; y += 5) {
      canvas.drawLine(Offset(10, y), Offset(50, y), plank);
    }
    final roof = Path()
      ..moveTo(5, 28)
      ..lineTo(30, 6)
      ..lineTo(55, 28)
      ..close();
    canvas.drawPath(roof, _p(0xFFC0564A));
    canvas.drawPath(
        Path()
          ..moveTo(30, 6)
          ..lineTo(55, 28)
          ..lineTo(42, 28)
          ..close(),
        _p(0xFFA4453B));
    final shingle = _line(0x66FFF4DA, 1);
    for (final y in const [14.0, 20.0, 26.0]) {
      final half = (y - 6) * 25 / 22;
      canvas.drawLine(Offset(30 - half, y), Offset(30 + half, y), shingle);
    }
    canvas.drawLine(
        const Offset(5, 28), const Offset(55, 28), _line(0xFF7A3A30, 2));
    // Arched door with a cushion inside.
    final door = Path()
      ..moveTo(23, 54)
      ..lineTo(23, 41)
      ..arcToPoint(const Offset(37, 41), radius: const Radius.circular(7))
      ..lineTo(37, 54)
      ..close();
    canvas.drawPath(door, _p(0xFF5A3A2A));
    canvas.drawOval(const Rect.fromLTWH(24, 49, 12, 5), _p(0xFFE88A95));
    // Round window and a little paw sign.
    canvas.drawCircle(const Offset(43, 36), 3.5, _p(0xFF7FB3C7));
    canvas.drawCircle(const Offset(43, 36), 3.5, _line(0xFF8C5A34, 1.2));
    canvas.drawCircle(const Offset(30, 19), 4.5, _p(0xFFFFF4DA));
    canvas.drawCircle(const Offset(30, 20.3), 1.6, _p(0xFFC0564A));
    for (final d in const [
      Offset(28, 17.6),
      Offset(30, 17),
      Offset(32, 17.6)
    ]) {
      canvas.drawCircle(d, .8, _p(0xFFC0564A));
    }
  }

  void _sofa(Canvas canvas) {
    // Two-seat sofa: back, arms, seat cushions with seams, legs, a pillow.
    for (final x in const [10.0, 47.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 47, 3, 6), _p(0xFF5A3214));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 18, 48, 22), const Radius.circular(7)),
        _p(0xFF5E8E7C));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(9, 20, 42, 10), const Radius.circular(5)),
        _p(0xFF6E9C8A));
    canvas.drawLine(
        const Offset(30, 21), const Offset(30, 38), _line(0x553E6658, 1));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 34, 44, 14), const Radius.circular(5)),
        _p(0xFF86B3A1));
    canvas.drawRect(const Rect.fromLTWH(8, 44, 44, 4), _p(0xFF6E9C8A));
    canvas.drawLine(
        const Offset(30, 35), const Offset(30, 47), _line(0x663E6658, 1.2));
    for (final x in const [2.0, 50.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 28, 8, 22), const Radius.circular(4)),
          _p(0xFF5E8E7C));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, 28, 8, 5), const Radius.circular(4)),
          _p(0xFF7AA898));
    }
    canvas.save();
    canvas.translate(17, 31);
    canvas.rotate(-.25);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -5, 12, 10), const Radius.circular(3)),
        _p(0xFFF2C7A0));
    canvas.drawLine(
        const Offset(-4, 0), const Offset(4, 0), _line(0xFFE0A07A, 1));
    canvas.restore();
  }

  void _shelf(Canvas canvas) {
    // Wall shelf on brackets with books, a plant and a little cat figurine.
    canvas.drawRect(const Rect.fromLTWH(4, 38, 52, 5), _p(0xFF8C5A34));
    canvas.drawRect(const Rect.fromLTWH(4, 38, 52, 2), _p(0xFFA9714A));
    for (final x in const [10.0, 46.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 43)
            ..lineTo(x + 4, 43)
            ..lineTo(x, 49)
            ..close(),
          _p(0xFF6E4428));
    }
    const books = [
      (0xFFD9657B, 20.0),
      (0xFF3E9FB0, 17.0),
      (0xFFFFC24D, 21.0),
      (0xFF6B9E4E, 15.0)
    ];
    var bx = 8.0;
    for (final (c, h) in books) {
      canvas.drawRect(Rect.fromLTWH(bx, 38 - h, 5, h), _p(c));
      canvas.drawLine(Offset(bx + 1, 38 - h + 3), Offset(bx + 4, 38 - h + 3),
          _line(0x88FFF4DA, 1));
      bx += 5.5;
    }
    canvas.save();
    canvas.translate(33, 38);
    canvas.rotate(-.35);
    canvas.drawRect(const Rect.fromLTWH(0, -16, 5, 16), _p(0xFFB9A4E8));
    canvas.restore();
    canvas.drawRect(const Rect.fromLTWH(44, 30, 9, 8), _p(0xFFC9714A));
    final leaf = _p(0xFF5E9A55);
    for (final d in const [Offset(46, 25), Offset(49, 22), Offset(52, 26)]) {
      canvas.drawOval(Rect.fromCenter(center: d, width: 5, height: 9), leaf);
    }
    canvas.drawCircle(const Offset(40, 34), 3, _p(0xFF5A3214));
    canvas.drawPath(
        Path()
          ..moveTo(37.5, 32)
          ..lineTo(38.5, 29)
          ..lineTo(40, 31.5)
          ..lineTo(41.5, 29)
          ..lineTo(42.5, 32)
          ..close(),
        _p(0xFF5A3214));
  }

  void _frames(Canvas canvas) {
    // Two framed pictures: a cat portrait and a fish, hung from a nail.
    canvas.drawLine(
        const Offset(30, 8), const Offset(14, 16), _line(0xFF8C5A34, .8));
    canvas.drawLine(
        const Offset(30, 8), const Offset(46, 18), _line(0xFF8C5A34, .8));
    canvas.drawCircle(const Offset(30, 8), 1.5, _p(0xFF5A3214));
    canvas.drawRect(const Rect.fromLTWH(4, 16, 22, 28), _p(0xFFB27A3E));
    canvas.drawRect(const Rect.fromLTWH(7, 19, 16, 22), _p(0xFFF2A65A));
    canvas.drawCircle(const Offset(15, 32), 6, _p(0xFFFFF4DA));
    canvas.drawPath(
        Path()
          ..moveTo(10, 29)
          ..lineTo(11, 23)
          ..lineTo(14, 27)
          ..moveTo(20, 29)
          ..lineTo(19, 23)
          ..lineTo(16, 27),
        _p(0xFFFFF4DA));
    canvas.drawCircle(const Offset(13, 31), .9, _p(0xFF5A3214));
    canvas.drawCircle(const Offset(17, 31), .9, _p(0xFF5A3214));
    canvas.drawRect(const Rect.fromLTWH(34, 18, 22, 22), _p(0xFF8C5A34));
    canvas.drawRect(const Rect.fromLTWH(37, 21, 16, 16), _p(0xFF7FB3C7));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(45, 29), width: 9, height: 5),
        _p(0xFFF28A3A));
    canvas.drawPath(
        Path()
          ..moveTo(41, 29)
          ..lineTo(38.5, 27)
          ..lineTo(38.5, 31)
          ..close(),
        _p(0xFFF28A3A));
    canvas.drawLine(
        const Offset(38, 35), const Offset(52, 35), _line(0x88FFFFFF, 1));
  }

  void _rug(Canvas canvas) {
    // Oval rug with a border, an inner ring, a paw motif and fringe.
    final fringe = _line(0xFFE0A88E, 1);
    for (var a = 0.0; a < math.pi * 2; a += .18) {
      final p = Offset(30 + math.cos(a) * 28, 38 + math.sin(a) * 9);
      canvas.drawLine(
          p, p + Offset(math.cos(a) * 2, math.sin(a) * 1.2), fringe);
    }
    const rug = Rect.fromLTWH(2, 29, 56, 18);
    canvas.drawOval(rug, _p(0xFFE8B4A0));
    canvas.drawOval(rug.deflate(3), _line(0xFFF6D4C4, 1.5));
    canvas.drawOval(rug.deflate(7), _p(0xFFF0C6B4));
    canvas.drawOval(rug.deflate(9), _line(0xFFD99A86, 1));
    final paw = _p(0x66D99A86);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(30, 39.5), width: 5, height: 3.5),
        paw);
    for (final d in const [
      Offset(27.2, 37),
      Offset(30, 36.2),
      Offset(32.8, 37)
    ]) {
      canvas.drawCircle(d, 1, paw);
    }
  }

  void _lamp(Canvas canvas) {
    // Floor lamp: round base, slim pole, pleated shade and a warm glow.
    canvas.drawCircle(const Offset(30, 16), 14, _p(0x33FFD36B));
    canvas.drawOval(const Rect.fromLTWH(22, 52, 16, 4), _p(0xFF5A3214));
    canvas.drawLine(
        const Offset(30, 53), const Offset(30, 20), _line(0xFF5A3214, 1.6));
    canvas.drawLine(
        const Offset(30, 34), const Offset(33, 33), _line(0xFFB27A3E, 1));
    final shade = Path()
      ..moveTo(21, 21)
      ..lineTo(39, 21)
      ..lineTo(35, 7)
      ..lineTo(25, 7)
      ..close();
    canvas.drawPath(shade, _p(0xFFFFD36B));
    canvas.drawPath(
        Path()
          ..moveTo(32, 21)
          ..lineTo(39, 21)
          ..lineTo(35, 7)
          ..lineTo(31, 7)
          ..close(),
        _p(0xFFE8B23A));
    final pleat = _line(0x55B27A3E, .7);
    for (final x in const [27.0, 30.0, 33.0]) {
      canvas.drawLine(Offset(x - 1.5, 21), Offset(x - .5, 7), pleat);
    }
    canvas.drawLine(
        const Offset(21, 21), const Offset(39, 21), _line(0xFFB27A3E, 1));
  }

  @override
  bool shouldRepaint(CampDecorPainter oldDelegate) => oldDelegate.id != id;
}
