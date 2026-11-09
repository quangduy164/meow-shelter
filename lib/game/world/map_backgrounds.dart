import 'dart:math' as math;
import 'package:flutter/rendering.dart';

/// Full indoor scene for the warehouse map, in a 1000x500 design space.
class WarehousePainter extends CustomPainter {
  const WarehousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    // Back wall: vertical wooden boards.
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1000, 122),
        Paint()..color = const Color(0xFF8E6443));
    for (var x = 0.0; x < 1000; x += 38) {
      canvas.drawRect(
          Rect.fromLTWH(x, 0, 36, 122),
          Paint()
            ..color = (x ~/ 38).isEven
                ? const Color(0xFF9B6E4A)
                : const Color(0xFF936846));
      canvas.drawLine(
          Offset(x, 0),
          Offset(x, 122),
          Paint()
            ..color = const Color(0xFF6E4A2E)
            ..strokeWidth = 2);
    }
    // Crossbeam and rafters.
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1000, 14),
        Paint()..color = const Color(0xFF5E3D25));
    for (final window in [const Offset(150, 22), const Offset(780, 22)]) {
      _window(canvas, window);
    }
    _shelf(canvas, const Offset(330, 30));
    _shelf(canvas, const Offset(560, 30));
    for (final x in [270.0, 500.0, 730.0]) {
      _lamp(canvas, Offset(x, 0));
    }
    // Baseboard.
    canvas.drawRect(const Rect.fromLTWH(0, 112, 1000, 10),
        Paint()..color = const Color(0xFF5E3D25));
    // Floor planks.
    canvas.drawRect(const Rect.fromLTWH(0, 122, 1000, 378),
        Paint()..color = const Color(0xFFC9A06C));
    final seam = Paint()
      ..color = const Color(0x66855A2E)
      ..strokeWidth = 1.5;
    final grain = math.Random(12);
    for (var row = 0; row * 24.0 + 122 < 500; row++) {
      final y = 122 + row * 24.0;
      canvas.drawRect(
          Rect.fromLTWH(0, y, 1000, 24),
          Paint()
            ..color = Color.lerp(const Color(0xFFC9A06C),
                const Color(0xFFB98F5C), grain.nextDouble() * .6)!);
      canvas.drawLine(Offset(0, y), Offset(1000, y), seam);
      for (var x = (row.isEven ? 0.0 : 70.0); x < 1000; x += 140) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 24), seam);
        canvas.drawCircle(Offset(x + 6, y + 12), 1.2,
            Paint()..color = const Color(0xFF6E4A2E));
      }
    }
    // Sunbeams from the windows.
    for (final x in [150.0, 780.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 122)
            ..lineTo(x + 70, 122)
            ..lineTo(x + 150, 330)
            ..lineTo(x + 30, 330)
            ..close(),
          Paint()..color = const Color(0x1FFFF3C4));
    }
    // Yellow safety lines along the aisle.
    final stripe = Paint()..color = const Color(0xCCE8B23A);
    for (var x = 230.0; x < 770; x += 26) {
      canvas.drawRect(Rect.fromLTWH(x, 132, 14, 5), stripe);
    }
    _sack(canvas, const Offset(40, 470));
    _sack(canvas, const Offset(78, 478));
    _barrel(canvas, const Offset(955, 455));
    _pallet(canvas, const Offset(210, 470));
    _pallet(canvas, const Offset(740, 470));
    canvas.restore();
  }

  void _window(Canvas canvas, Offset o) {
    final frame = Rect.fromLTWH(o.dx, o.dy, 72, 56);
    canvas.drawRect(frame.inflate(5), Paint()..color = const Color(0xFF5E3D25));
    canvas.drawRect(
        frame,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBFE6EE), Color(0xFFEFF6DA)])
              .createShader(frame));
    canvas.drawCircle(
        o + const Offset(54, 16), 8, Paint()..color = const Color(0xCCFFE7A0));
    final bar = Paint()
      ..color = const Color(0xFF5E3D25)
      ..strokeWidth = 4;
    canvas.drawLine(frame.topCenter, frame.bottomCenter, bar);
    canvas.drawLine(frame.centerLeft, frame.centerRight, bar);
  }

  void _shelf(Canvas canvas, Offset o) {
    final board = Paint()..color = const Color(0xFF5E3D25);
    for (final y in [34.0, 72.0]) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy + y, 110, 6), board);
    }
    const colors = [
      Color(0xFFD9A35E),
      Color(0xFFB07A45),
      Color(0xFFE8C88A),
      Color(0xFF8FA6A0)
    ];
    for (var i = 0; i < 4; i++) {
      final w = 20.0 + (i % 2) * 6;
      final h = 22.0 + (i % 3) * 5;
      canvas.drawRect(Rect.fromLTWH(o.dx + 6 + i * 26, o.dy + 34 - h, w, h),
          Paint()..color = colors[i]);
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
          Rect.fromLTWH(o.dx + 10 + i * 32, o.dy + 54, 26, 18),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFE0D2B0) : const Color(0xFFCDB98E));
    }
  }

  void _lamp(Canvas canvas, Offset top) {
    canvas.drawLine(
        top,
        top + const Offset(0, 24),
        Paint()
          ..color = const Color(0xFF3E2A1A)
          ..strokeWidth = 2);
    canvas.drawPath(
        Path()
          ..moveTo(top.dx - 14, top.dy + 34)
          ..lineTo(top.dx - 6, top.dy + 24)
          ..lineTo(top.dx + 6, top.dy + 24)
          ..lineTo(top.dx + 14, top.dy + 34)
          ..close(),
        Paint()..color = const Color(0xFF4F6B63));
    canvas.drawCircle(
        top + const Offset(0, 36), 5, Paint()..color = const Color(0xFFFFE9A8));
    canvas.drawCircle(top + const Offset(0, 36), 16,
        Paint()..color = const Color(0x33FFE9A8));
  }

  void _sack(Canvas canvas, Offset o) {
    canvas.drawOval(
        Rect.fromCenter(center: o + const Offset(0, 12), width: 44, height: 10),
        Paint()..color = const Color(0x33402A14));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: o, width: 38, height: 30),
            const Radius.circular(12)),
        Paint()..color = const Color(0xFFE2CFA0));
    canvas.drawLine(
        o + const Offset(-8, -14),
        o + const Offset(8, -14),
        Paint()
          ..color = const Color(0xFF9C7B4A)
          ..strokeWidth = 3);
  }

  void _barrel(Canvas canvas, Offset o) {
    final body = Rect.fromCenter(center: o, width: 46, height: 56);
    canvas.drawOval(
        Rect.fromCenter(center: o + const Offset(0, 28), width: 52, height: 10),
        Paint()..color = const Color(0x33402A14));
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(14)),
        Paint()..color = const Color(0xFF9C6A3E));
    for (final y in [-16.0, 16.0]) {
      canvas.drawRect(Rect.fromLTWH(body.left, o.dy + y - 3, body.width, 6),
          Paint()..color = const Color(0xFF55595A));
    }
  }

  void _pallet(Canvas canvas, Offset o) {
    final slat = Paint()..color = const Color(0xFFB88A55);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
          Rect.fromLTWH(o.dx - 40 + i * 21, o.dy - 6, 17, 12), slat);
    }
    canvas.drawRect(Rect.fromLTWH(o.dx - 42, o.dy + 6, 84, 5),
        Paint()..color = const Color(0xFF8A6238));
  }

  @override
  bool shouldRepaint(covariant WarehousePainter oldDelegate) => false;
}

/// Full lakeside scene for the pond map, in a 1000x500 design space.
class PondPainter extends CustomPainter {
  const PondPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 120),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7C99A), Color(0xFFF4E6C2)])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 120)));
    canvas.drawCircle(
        const Offset(180, 58), 30, Paint()..color = const Color(0xFFFFD98A));
    canvas.drawCircle(
        const Offset(180, 58), 46, Paint()..color = const Color(0x33FFE2A4));
    // Distant hills and the far shore.
    final hills = Path()..moveTo(0, 92);
    for (var x = 0.0; x <= 1000; x += 125) {
      hills.quadraticBezierTo(
          x + 62, 52 + (x % 250 == 0 ? 0 : 18), x + 125, 92);
    }
    hills
      ..lineTo(1000, 130)
      ..lineTo(0, 130)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF9EBB8A));
    canvas.drawRect(const Rect.fromLTWH(0, 100, 1000, 22),
        Paint()..color = const Color(0xFF6FAFB8));
    for (var x = 20.0; x < 1000; x += 90) {
      canvas.drawLine(
          Offset(x, 108),
          Offset(x + 30, 108),
          Paint()
            ..color = const Color(0x88E8F8F6)
            ..strokeWidth = 2);
    }
    for (final x in [70.0, 420.0, 610.0, 930.0]) {
      _willow(canvas, Offset(x, 118));
    }
    // Lush lawn.
    canvas.drawRect(
        const Rect.fromLTWH(0, 118, 1000, 382),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8FC07C), Color(0xFFA5CF8C)])
              .createShader(const Rect.fromLTWH(0, 118, 1000, 382)));
    final random = math.Random(33);
    final blade = Paint()
      ..color = const Color(0x55507F44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 220; i++) {
      final x = random.nextDouble() * 1000;
      final y = 130 + random.nextDouble() * 365;
      if (x > 220 && x < 780 && y < 440) continue;
      canvas.drawPath(
          Path()
            ..moveTo(x - 3, y)
            ..lineTo(x - 4, y - 5)
            ..moveTo(x, y)
            ..lineTo(x + 1, y - 7)
            ..moveTo(x + 3, y)
            ..lineTo(x + 6, y - 4),
          blade);
    }
    for (final o in [
      const Offset(40, 300),
      const Offset(960, 300),
      const Offset(250, 480),
      const Offset(760, 480)
    ]) {
      _flowers(canvas, o);
    }
    for (final o in [const Offset(20, 470), const Offset(980, 470)]) {
      _reeds(canvas, o);
    }
    _dock(canvas, const Offset(880, 470));
    for (final rock in [const Offset(120, 486), const Offset(640, 490)]) {
      canvas.drawOval(Rect.fromCenter(center: rock, width: 30, height: 14),
          Paint()..color = const Color(0xFFB7BBA8));
      canvas.drawOval(
          Rect.fromCenter(
              center: rock + const Offset(-4, -3), width: 14, height: 5),
          Paint()..color = const Color(0xFFDDE0CF));
    }
    canvas.restore();
  }

  void _willow(Canvas canvas, Offset root) {
    canvas.drawRect(Rect.fromLTWH(root.dx - 5, root.dy - 40, 10, 40),
        Paint()..color = const Color(0xFF7D5E40));
    canvas.drawOval(
        Rect.fromCenter(
            center: root + const Offset(0, -52), width: 90, height: 56),
        Paint()..color = const Color(0xFF6E9E5E));
    final strand = Paint()
      ..color = const Color(0xFF86B26D)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final x = root.dx - 40 + i * 10.0;
      canvas.drawLine(Offset(x, root.dy - 54),
          Offset(x + 3, root.dy - 14 - (i % 3) * 8), strand);
    }
  }

  void _flowers(Canvas canvas, Offset o) {
    canvas.drawOval(Rect.fromCenter(center: o, width: 54, height: 12),
        Paint()..color = const Color(0xFF79AE68));
    for (var i = 0; i < 5; i++) {
      final head = o + Offset((i - 2) * 9, -10 - (i % 2) * 6.0);
      canvas.drawLine(
          o + Offset((i - 2) * 9, 0),
          head,
          Paint()
            ..color = const Color(0xFF5D905E)
            ..strokeWidth = 1.5);
      canvas.drawCircle(
          head,
          4,
          Paint()
            ..color =
                i.isEven ? const Color(0xFFFFF1F4) : const Color(0xFFB6A2E0));
      canvas.drawCircle(head, 1.5, Paint()..color = const Color(0xFFE8BA5A));
    }
  }

  void _reeds(Canvas canvas, Offset base) {
    for (var k = 0; k < 6; k++) {
      final x = base.dx + (k - 3) * 6;
      final top =
          Offset(x + (k.isEven ? -4 : 4), base.dy - 46 - (k % 3) * 10.0);
      canvas.drawLine(
          Offset(x, base.dy),
          top,
          Paint()
            ..color = const Color(0xFF5E8B4A)
            ..strokeWidth = 2.2);
      if (k.isOdd) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: top, width: 6, height: 15),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFF8A5A33));
      }
    }
  }

  void _dock(Canvas canvas, Offset o) {
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
          Rect.fromLTWH(o.dx - 50 + i * 20, o.dy - 14, 18, 30),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFC79A64) : const Color(0xFFB8895A));
    }
    for (final x in [-52.0, 48.0]) {
      canvas.drawRect(Rect.fromLTWH(o.dx + x, o.dy - 24, 6, 44),
          Paint()..color = const Color(0xFF7D5A38));
    }
  }

  @override
  bool shouldRepaint(covariant PondPainter oldDelegate) => false;
}
