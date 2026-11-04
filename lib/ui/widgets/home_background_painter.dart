import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nền trang chủ: hoàng hôn ấm áp, đồi thoải, trạm cứu hộ mèo bên trái,
/// hồ cá bên phải và dây cờ phía trên.
///
/// Vẽ trong hệ toạ độ cao 600 với chiều rộng [w] co giãn theo màn hình,
/// nên hình tròn không bị méo trên các tỉ lệ màn hình khác nhau.
class HomeBackgroundPainter extends CustomPainter {
  const HomeBackgroundPainter();

  static const _h = 600.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / _h;
    final w = size.width / s;
    canvas.save();
    canvas.scale(s, s);

    _sky(canvas, w);
    _sun(canvas, Offset(w * .3, 205));
    _cloud(canvas, Offset(w * .12, 110), 1);
    _cloud(canvas, Offset(w * .56, 70), .75);
    _cloud(canvas, Offset(w * .86, 140), .9);
    _birds(canvas, Offset(w * .68, 105));

    _hill(canvas, w, 330, 60, const Color(0xFFB9D3A0), phase: 0);
    _hill(canvas, w, 370, 45, const Color(0xFF9CC584), phase: 1.7);
    _fence(canvas, w, 395);
    _hill(canvas, w, 430, 30, const Color(0xFF86B86E), phase: 3.1);

    _tree(canvas, Offset(w * .04, 420), 1.1);
    _tree(canvas, Offset(w * .96, 410), 1.25);
    _lake(canvas, Offset(w * .78, 540), w);
    _pawTrail(canvas, w);
    _flowers(canvas, w);
    _bunting(canvas, w);
    _vignette(canvas, w);

    canvas.restore();
  }

  void _sky(Canvas canvas, double w) {
    final rect = Rect.fromLTWH(0, 0, w, _h);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7EC4E0),
              Color(0xFFBFE3E6),
              Color(0xFFFFE3B8),
              Color(0xFFFFC98F),
            ],
            stops: [0, .35, .58, .75],
          ).createShader(rect));
  }

  void _sun(Canvas canvas, Offset c) {
    canvas.drawCircle(
        c,
        260,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x99FFF6D0),
            Color(0x33FFE7A8),
            Color(0x00FFE7A8),
          ], stops: [
            0,
            .45,
            1
          ]).createShader(Rect.fromCircle(center: c, radius: 260)));
    final ray = Paint()..color = const Color(0x22FFFFFF);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(
                c.dx + math.cos(a - .09) * 330, c.dy + math.sin(a - .09) * 330)
            ..lineTo(
                c.dx + math.cos(a + .09) * 330, c.dy + math.sin(a + .09) * 330)
            ..close(),
          ray);
    }
  }

  void _cloud(Canvas canvas, Offset o, double k) {
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.scale(k, k);
    final shade = Paint()..color = const Color(0x40C7A27C);
    final cloud = Paint()..color = const Color(0xF2FFFBF0);
    for (final p in [shade, cloud]) {
      final dy = identical(p, shade) ? 5.0 : 0.0;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-70, -6 + dy, 150, 30), const Radius.circular(15)),
          p);
      canvas.drawCircle(Offset(-28, -6 + dy), 24, p);
      canvas.drawCircle(Offset(12, -16 + dy), 32, p);
      canvas.drawCircle(Offset(48, -4 + dy), 20, p);
    }
    canvas.restore();
  }

  void _birds(Canvas canvas, Offset o) {
    final p = Paint()
      ..color = const Color(0x997A5A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final d in const [Offset(0, 0), Offset(26, 12), Offset(-20, 18)]) {
      final c = o + d;
      canvas.drawPath(
          Path()
            ..moveTo(c.dx - 8, c.dy)
            ..quadraticBezierTo(c.dx - 4, c.dy - 5, c.dx, c.dy)
            ..quadraticBezierTo(c.dx + 4, c.dy - 5, c.dx + 8, c.dy),
          p);
    }
  }

  void _hill(Canvas canvas, double w, double top, double amp, Color color,
      {required double phase}) {
    final path = Path()..moveTo(0, _h);
    for (var x = 0.0; x <= w + 20; x += 20) {
      final y = top +
          math.sin(x / 210 + phase) * amp * .55 +
          math.sin(x / 95 + phase * 2) * amp * .2;
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, _h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _fence(Canvas canvas, double w, double y) {
    final wood = Paint()..color = const Color(0xFFF7EBD0);
    final edge = Paint()..color = const Color(0xFFD4B48A);
    canvas.drawRect(Rect.fromLTWH(0, y + 6, w, 5), edge);
    canvas.drawRect(Rect.fromLTWH(0, y + 4, w, 5), wood);
    canvas.drawRect(Rect.fromLTWH(0, y + 22, w, 5), wood);
    for (var x = -6.0; x < w; x += 28) {
      final post = Path()
        ..moveTo(x, y)
        ..lineTo(x + 5, y - 6)
        ..lineTo(x + 10, y)
        ..lineTo(x + 10, y + 36)
        ..lineTo(x, y + 36)
        ..close();
      canvas.drawPath(post.shift(const Offset(1.5, 1.5)), edge);
      canvas.drawPath(post, wood);
    }
  }

  void _tree(Canvas canvas, Offset base, double k) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(k, k);
    canvas.drawOval(const Rect.fromLTWH(-40, -6, 80, 14),
        Paint()..color = const Color(0x33405A30));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-7, -60, 14, 62), const Radius.circular(5)),
        Paint()..color = const Color(0xFF8A5A36));
    final leaf = Paint()..color = const Color(0xFF5E9A55);
    final light = Paint()..color = const Color(0xFF7DB766);
    canvas.drawCircle(const Offset(-24, -72), 28, leaf);
    canvas.drawCircle(const Offset(24, -74), 28, leaf);
    canvas.drawCircle(const Offset(0, -100), 34, leaf);
    canvas.drawCircle(const Offset(-8, -108), 20, light);
    canvas.drawCircle(const Offset(-28, -80), 14, light);
    canvas.restore();
  }

  void _lake(Canvas canvas, Offset c, double w) {
    final rect = Rect.fromCenter(center: c, width: 360, height: 110);
    canvas.drawOval(rect.inflate(8), Paint()..color = const Color(0xFFC9B07A));
    canvas.drawOval(
        rect,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6CC6CF), Color(0xFF3393A8)])
              .createShader(rect));
    final wave = Paint()
      ..color = const Color(0x88E6FAF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = c.dx - 120 + i * 70.0;
      final y = c.dy - 20 + (i % 2) * 22.0;
      canvas.drawArc(
          Rect.fromLTWH(x, y, 40, 12), math.pi, math.pi, false, wave);
    }
    // Lá súng
    canvas.drawCircle(c + const Offset(120, 12), 14,
        Paint()..color = const Color(0xFF5E9A55));
    canvas.drawCircle(c + const Offset(-140, 4), 10,
        Paint()..color = const Color(0xFF5E9A55));
    // Phao câu
    canvas.drawCircle(
        c + const Offset(30, 0), 7, Paint()..color = const Color(0xFFE85A4F));
    canvas.drawRect(
        Rect.fromCenter(center: c + const Offset(30, 0), width: 14, height: 3),
        Paint()..color = Colors.white);
  }

  void _pawTrail(Canvas canvas, double w) {
    const color = Color(0x40FFFFFF);
    for (var i = 0; i < 9; i++) {
      final t = i / 8;
      final x = w * (.27 + t * .32);
      final y = 560 - math.sin(t * math.pi) * 40 + (i.isEven ? -8 : 8);
      _paw(canvas, Offset(x, y), 7, color);
    }
  }

  void _paw(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(0, r * .35), width: r * 1.6, height: r * 1.3),
        p);
    for (final d in [
      Offset(-r * .85, -r * .35),
      Offset(-r * .3, -r * .85),
      Offset(r * .3, -r * .85),
      Offset(r * .85, -r * .35),
    ]) {
      canvas.drawCircle(c + d, r * .32, p);
    }
  }

  void _flowers(Canvas canvas, double w) {
    final random = math.Random(7);
    const colors = [Color(0xFFFFF4DA), Color(0xFFF2A2AE), Color(0xFFFFD86B)];
    for (var i = 0; i < 40; i++) {
      final x = random.nextDouble() * w;
      final y = 450 + random.nextDouble() * 140;
      if (random.nextBool()) {
        canvas.drawCircle(
            Offset(x, y), 3.5, Paint()..color = colors[i % colors.length]);
        canvas.drawCircle(
            Offset(x, y), 1.3, Paint()..color = const Color(0xFFE0A030));
      } else {
        final g = Paint()
          ..color = const Color(0x665C8F49)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x, y), Offset(x - 3, y - 9), g);
        canvas.drawLine(Offset(x + 4, y), Offset(x + 6, y - 10), g);
      }
    }
  }

  void _bunting(Canvas canvas, double w) {
    final string = Paint()
      ..color = const Color(0xFF8A5A36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const sag = 34.0;
    double yAt(double x) => 6 + math.sin(x / w * math.pi) * sag;
    final path = Path()..moveTo(0, yAt(0));
    for (var x = 10.0; x <= w; x += 10) {
      path.lineTo(x, yAt(x));
    }
    canvas.drawPath(path, string);
    const colors = [
      Color(0xFFE0703F),
      Color(0xFFFFD86B),
      Color(0xFF6CC6CF),
      Color(0xFFF2A2AE),
      Color(0xFF86B86E),
    ];
    var i = 0;
    for (var x = 30.0; x < w - 10; x += 52, i++) {
      final y = yAt(x);
      canvas.drawPath(
          Path()
            ..moveTo(x - 13, y)
            ..lineTo(x + 13, y)
            ..lineTo(x, y + 28)
            ..close(),
          Paint()..color = colors[i % colors.length]);
    }
  }

  void _vignette(Canvas canvas, double w) {
    final rect = Rect.fromLTWH(0, 0, w, _h);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            radius: 1.1,
            colors: [Color(0x00000000), Color(0x33402010)],
            stops: [.6, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant HomeBackgroundPainter oldDelegate) => false;
}
