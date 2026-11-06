import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Home background: a soft dusk sky, layered hills and a winding path that
/// leads to the shelter on the far right. Details stay near the edges so the
/// logo, the play button and the mode tiles always sit on calm areas.
///
/// Drawn in a 600-high space; width follows the screen ratio so shapes keep
/// their proportions on every device.
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
    _stars(canvas, w);
    _sun(canvas, Offset(w * .42, 360));
    _cloud(canvas, Offset(w * .08, 90), 1);
    _cloud(canvas, Offset(w * .5, 60), .7);
    _cloud(canvas, Offset(w * .9, 120), .85);
    _hills(canvas, w, 360, 70, const Color(0xFFB59BC8), 0);
    _hills(canvas, w, 410, 50, const Color(0xFF9DB98F), 1.4);
    _hills(canvas, w, 460, 34, const Color(0xFF7FAA6E), 2.7);
    _hills(canvas, w, 520, 14, const Color(0xFF6A9A5C), 4.1);
    _shelter(canvas, Offset(w - 90, 440));
    _tree(canvas, const Offset(40, 470), 1.1);
    _path(canvas, w);
    _flowers(canvas, w);
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
              Color(0xFF6E6BB0),
              Color(0xFFB08DC4),
              Color(0xFFF2B6A0),
              Color(0xFFFFD9A0),
            ],
            stops: [0, .32, .55, .7],
          ).createShader(rect));
  }

  void _stars(Canvas canvas, double w) {
    final random = math.Random(3);
    final p = Paint()..color = const Color(0xCCFFF6E2);
    for (var i = 0; i < 40; i++) {
      final o = Offset(random.nextDouble() * w, random.nextDouble() * 160);
      canvas.drawCircle(o, random.nextDouble() * 1.6 + .6, p);
    }
  }

  void _sun(Canvas canvas, Offset c) {
    canvas.drawCircle(
        c,
        230,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x88FFF1C4),
            Color(0x00FFE0A8),
          ]).createShader(Rect.fromCircle(center: c, radius: 230)));
    canvas.drawCircle(c, 70, Paint()..color = const Color(0xFFFFE3A6));
  }

  void _cloud(Canvas canvas, Offset o, double k) {
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.scale(k, k);
    final p = Paint()..color = const Color(0xBFFFF1EA);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-80, -4, 170, 28), const Radius.circular(14)),
        p);
    canvas.drawCircle(const Offset(-30, -4), 24, p);
    canvas.drawCircle(const Offset(14, -14), 32, p);
    canvas.drawCircle(const Offset(52, -2), 20, p);
    canvas.restore();
  }

  void _hills(Canvas canvas, double w, double top, double amp, Color color,
      double phase) {
    final path = Path()..moveTo(0, _h);
    for (var x = 0.0; x <= w + 20; x += 16) {
      path.lineTo(
          x,
          top +
              math.sin(x / 230 + phase) * amp * .6 +
              math.sin(x / 90 + phase * 2) * amp * .15);
    }
    path
      ..lineTo(w, _h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _path(Canvas canvas, double w) {
    final path = Path()
      ..moveTo(w * .05, _h)
      ..cubicTo(w * .3, 540, w * .55, 600, w * .75, 520)
      ..quadraticBezierTo(w * .85, 490, w - 90, 486);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE9CF9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round);
    final paw = Paint()..color = const Color(0x55A07A4A);
    for (final metric in path.computeMetrics()) {
      for (var d = 30.0; d < metric.length - 40; d += 46) {
        final t = metric.getTangentForOffset(d)!;
        final side = (d ~/ 46).isEven ? 6.0 : -6.0;
        final n = Offset(-t.vector.dy, t.vector.dx) * side;
        canvas.drawCircle(t.position + n, 4, paw);
      }
    }
  }

  /// The shelter the path leads to: a small barn with a paw sign and a lit
  /// window.
  void _shelter(Canvas canvas, Offset base) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.drawOval(const Rect.fromLTWH(-70, 36, 140, 18),
        Paint()..color = const Color(0x33402A1A));
    canvas.drawRect(const Rect.fromLTWH(-56, -10, 112, 56),
        Paint()..color = const Color(0xFFF2D7B4));
    canvas.drawPath(
        Path()
          ..moveTo(-68, -6)
          ..lineTo(0, -58)
          ..lineTo(68, -6)
          ..close(),
        Paint()..color = const Color(0xFFC0564A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-14, 14, 28, 32), const Radius.circular(14)),
        Paint()..color = const Color(0xFF7A4A33));
    canvas.drawRect(const Rect.fromLTWH(-46, 4, 20, 18),
        Paint()..color = const Color(0xFFFFE08A));
    canvas.drawRect(const Rect.fromLTWH(26, 4, 20, 18),
        Paint()..color = const Color(0xFFFFE08A));
    canvas.drawCircle(
        const Offset(0, -24), 12, Paint()..color = const Color(0xFFFFF6E2));
    final pad = Paint()..color = const Color(0xFFC0564A);
    canvas.drawCircle(const Offset(0, -21), 4.5, pad);
    for (final d in const [Offset(-6, -28), Offset(0, -31), Offset(6, -28)]) {
      canvas.drawCircle(d, 2, pad);
    }
    canvas.restore();
  }

  void _tree(Canvas canvas, Offset base, double k) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(k, k);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -60, 12, 62), const Radius.circular(4)),
        Paint()..color = const Color(0xFF7A5236));
    final dark = Paint()..color = const Color(0xFF4F8A57);
    final light = Paint()..color = const Color(0xFF6BA765);
    canvas.drawOval(const Rect.fromLTWH(-40, -132, 80, 92), dark);
    canvas.drawOval(const Rect.fromLTWH(-30, -128, 50, 60), light);
    canvas.restore();
  }

  void _flowers(Canvas canvas, double w) {
    final random = math.Random(11);
    const colors = [Color(0xFFFFF6E2), Color(0xFFF7A9B8), Color(0xFFFFD36B)];
    for (var i = 0; i < 46; i++) {
      final x = random.nextDouble() * w;
      final y = 510 + random.nextDouble() * 85;
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = colors[i % colors.length]);
    }
  }

  void _vignette(Canvas canvas, double w) {
    final rect = Rect.fromLTWH(0, 0, w, _h);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            radius: 1.05,
            colors: [Color(0x00000000), Color(0x40301830)],
            stops: [.62, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant HomeBackgroundPainter oldDelegate) => false;
}
