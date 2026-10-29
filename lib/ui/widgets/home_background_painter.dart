import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeBackgroundPainter extends CustomPainter {
  const HomeBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 600);

    canvas.drawRect(const Rect.fromLTWH(0, 0, 1000, 600),
        Paint()..color = const Color(0xFFA9DDE2));
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 285),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF78C8DE), Color(0xFFD7F0D5)])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 285)));

    canvas.drawCircle(
        const Offset(820, 92), 42, Paint()..color = const Color(0xFFFFE6A1));
    canvas.drawCircle(
        const Offset(820, 92), 53, Paint()..color = const Color(0x35FFF3B8));
    _cloud(canvas, const Offset(160, 88), 1);
    _cloud(canvas, const Offset(555, 66), .8);

    _mountain(canvas, const Offset(50, 290), 240, 245, const Color(0xFF6DA7A1));
    _mountain(
        canvas, const Offset(370, 292), 290, 275, const Color(0xFF5E9899));
    _mountain(
        canvas, const Offset(730, 300), 265, 245, const Color(0xFF73A99A));

    canvas.drawRect(const Rect.fromLTWH(0, 280, 1000, 320),
        Paint()..color = const Color(0xFFA9C986));
    _fence(canvas);
    _shelter(canvas, const Offset(145, 340));
    _lake(canvas);
    _flowerPatch(canvas, const Offset(86, 506));
    _flowerPatch(canvas, const Offset(890, 510));
    _grass(canvas);
    canvas.restore();
  }

  void _cloud(Canvas canvas, Offset origin, double scale) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale, scale);
    final cloud = Paint()..color = const Color(0xB9F7F8E8);
    canvas.drawOval(const Rect.fromLTWH(-68, 0, 118, 25), cloud);
    canvas.drawCircle(const Offset(-22, 0), 25, cloud);
    canvas.drawCircle(const Offset(12, -8), 32, cloud);
    canvas.restore();
  }

  void _mountain(
      Canvas canvas, Offset base, double width, double height, Color color) {
    final path = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..lineTo(base.dx, base.dy - height)
      ..lineTo(base.dx + width / 2, base.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy - height)
          ..lineTo(base.dx - width * .08, base.dy - height * .57)
          ..lineTo(base.dx + width * .22, base.dy)
          ..lineTo(base.dx + width / 2, base.dy)
          ..close(),
        Paint()..color = color.withOpacity(.7));
  }

  void _fence(Canvas canvas) {
    final post = Paint()..color = const Color(0xFFF5EBCF);
    canvas.drawRect(const Rect.fromLTWH(0, 323, 1000, 8), post);
    canvas.drawRect(const Rect.fromLTWH(0, 356, 1000, 7), post);
    for (var i = 0; i < 34; i++) {
      final x = i * 31.0 - 10;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, 302 + (i % 2) * 3, 16, 74),
              const Radius.circular(3)),
          post);
      canvas.drawCircle(
          Offset(x + 8, 307), 2, Paint()..color = const Color(0xFFD0B98D));
    }
  }

  void _shelter(Canvas canvas, Offset origin) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.drawOval(const Rect.fromLTWH(-72, 78, 210, 28),
        Paint()..color = const Color(0x335C774B));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-56, -8, 166, 91), const Radius.circular(8)),
        Paint()..color = const Color(0xFFFFE7B0));
    canvas.drawPath(
        Path()
          ..moveTo(-70, -6)
          ..lineTo(26, -74)
          ..lineTo(124, -6)
          ..close(),
        Paint()..color = const Color(0xFF518678));
    canvas.drawPath(
        Path()
          ..moveTo(-70, -6)
          ..lineTo(26, -74)
          ..lineTo(47, -58)
          ..lineTo(-27, -6)
          ..close(),
        Paint()..color = const Color(0xFF78AE91));
    canvas.drawCircle(
        const Offset(26, 26), 30, Paint()..color = const Color(0xFF447564));
    canvas.drawCircle(const Offset(16, 18), 4, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(36, 18), 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        const Offset(16, 18), 1.8, Paint()..color = const Color(0xFF294941));
    canvas.drawCircle(
        const Offset(36, 18), 1.8, Paint()..color = const Color(0xFF294941));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, 42, 64, 40), const Radius.circular(20)),
        Paint()..color = const Color(0xFF356B5D));
    canvas.restore();
  }

  void _lake(Canvas canvas) {
    canvas.drawOval(const Rect.fromLTWH(520, 415, 410, 145),
        Paint()..color = const Color(0x42708F5C));
    canvas.drawOval(
        const Rect.fromLTWH(530, 395, 390, 145),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF55B8C2), Color(0xFF2F91A4)])
              .createShader(const Rect.fromLTWH(530, 395, 390, 145)));
    final wave = Paint()
      ..color = const Color(0x66D7F4E6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(Rect.fromLTWH(585 + i * 35.0, 425 + i * 16.0, 90, 18),
          math.pi, math.pi, false, wave);
    }
    canvas.drawCircle(
        const Offset(724, 460), 8, Paint()..color = const Color(0xFFE7C66F));
  }

  void _flowerPatch(Canvas canvas, Offset origin) {
    for (var i = 0; i < 6; i++) {
      final x = origin.dx + (i - 2.5) * 12;
      final y = origin.dy + math.sin(i) * 5;
      canvas.drawLine(
          Offset(x, y),
          Offset(x + 2, y - 22),
          Paint()
            ..color = const Color(0xFF4E8756)
            ..strokeWidth = 2);
      canvas.drawCircle(
          Offset(x + 2, y - 25),
          5,
          Paint()
            ..color =
                i.isEven ? const Color(0xFFFFE9D0) : const Color(0xFFE898A2));
      canvas.drawCircle(
          Offset(x + 2, y - 25), 1.5, Paint()..color = const Color(0xFFE7B958));
    }
  }

  void _grass(Canvas canvas) {
    final random = math.Random(17);
    for (var i = 0; i < 90; i++) {
      final x = random.nextDouble() * 1000;
      final y = 380 + random.nextDouble() * 205;
      if (x > 230 && x < 500 && y < 520) continue;
      canvas.drawLine(
          Offset(x, y),
          Offset(x + 3, y - 8),
          Paint()
            ..color = const Color(0x55729B58)
            ..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(covariant HomeBackgroundPainter oldDelegate) => false;
}
