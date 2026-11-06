import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The cat camp seen from inside a cosy room: patterned wallpaper, a window
/// on the garden, a sofa and shelf against the wall and a wooden floor.
/// The window follows the device clock so the room has a day, a
/// sunset and a night. Decorations sit on the floor below [floorLine].
class CampRoomPainter extends CustomPainter {
  CampRoomPainter({required this.hour});

  /// Local hour (0-23) driving the lighting.
  final int hour;

  /// Fraction of the height where the wall meets the floor.
  static const floorLine = .55;

  bool get _night => hour < 6 || hour >= 19;
  bool get _sunset => hour >= 17 && hour < 19;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorY = h * floorLine;
    _wall(canvas, w, floorY);
    _window(canvas, Rect.fromLTWH(w * .62, h * .08, w * .22, h * .34));
    _floor(canvas, w, h, floorY);
    if (_night) {
      canvas.drawRect(
          Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0x33201040));
    }
  }

  void _wall(Canvas canvas, double w, double floorY) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, floorY),
        Paint()..color = const Color(0xFFF6E3C6));
    // Wallpaper: soft vertical stripes and a scatter of paw prints.
    final stripe = Paint()..color = const Color(0xFFEFD6B2);
    for (var x = 0.0; x < w; x += 44) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 16, floorY), stripe);
    }
    final paw = Paint()..color = const Color(0x22B27A3E);
    for (var y = 30.0; y < floorY - 30; y += 70) {
      for (var x = 24.0 + ((y ~/ 70).isOdd ? 30 : 0); x < w; x += 90) {
        canvas.drawCircle(Offset(x, y + 4), 6, paw);
        for (final d in const [Offset(-6, -6), Offset(0, -9), Offset(6, -6)]) {
          canvas.drawCircle(Offset(x, y) + d, 2.6, paw);
        }
      }
    }
    // Wainscot rail where the wall meets the floor.
    canvas.drawRect(Rect.fromLTWH(0, floorY - 14, w, 14),
        Paint()..color = const Color(0xFFC9935E));
    canvas.drawRect(Rect.fromLTWH(0, floorY - 14, w, 3),
        Paint()..color = const Color(0xFFE4B783));
  }

  void _window(Canvas canvas, Rect r) {
    final sky = _night
        ? const [Color(0xFF283466), Color(0xFF4B4C86)]
        : _sunset
            ? const [Color(0xFFF59E7B), Color(0xFFFFD39A)]
            : const [Color(0xFF8FD3EE), Color(0xFFD7F1F6)];
    canvas.drawRRect(
        RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(10)),
        Paint()..color = const Color(0xFFB27A3E));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)));
    canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: sky)
              .createShader(r));
    if (_night) {
      canvas.drawCircle(r.topRight + Offset(-r.width * .28, r.height * .28),
          r.width * .1, Paint()..color = const Color(0xFFFFF4C8));
      final star = Paint()..color = const Color(0xCCFFFFFF);
      final random = math.Random(5);
      for (var i = 0; i < 10; i++) {
        canvas.drawCircle(
            Offset(r.left + random.nextDouble() * r.width,
                r.top + random.nextDouble() * r.height * .6),
            1.2,
            star);
      }
    } else {
      canvas.drawCircle(r.topLeft + Offset(r.width * .3, r.height * .32),
          r.width * .11, Paint()..color = const Color(0xFFFFE9A6));
    }
    // Garden hills and a fence outside.
    final hill = Path()..moveTo(r.left, r.bottom);
    for (var x = r.left; x <= r.right; x += 6) {
      hill.lineTo(x, r.bottom - r.height * (.22 + math.sin(x / 24) * .05));
    }
    hill
      ..lineTo(r.right, r.bottom)
      ..close();
    canvas.drawPath(
        hill,
        Paint()
          ..color = _night ? const Color(0xFF3E5A4A) : const Color(0xFF8EC07A));
    canvas.restore();
    final bar = Paint()
      ..color = const Color(0xFFB27A3E)
      ..strokeWidth = 5;
    canvas.drawLine(r.topCenter, r.bottomCenter, bar);
    canvas.drawLine(r.centerLeft, r.centerRight, bar);
    // Curtains and a sill.
    final curtain = Paint()..color = const Color(0xFFE57F82);
    for (final left in [true, false]) {
      final x = left ? r.left - 14 : r.right + 14;
      final dir = left ? 1.0 : -1.0;
      canvas.drawPath(
          Path()
            ..moveTo(x, r.top - 12)
            ..lineTo(x + dir * 34, r.top - 12)
            ..quadraticBezierTo(
                x + dir * 10, r.center.dy, x + dir * 26, r.bottom + 6)
            ..lineTo(x, r.bottom + 6)
            ..close(),
          curtain);
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left - 18, r.bottom + 6, r.width + 36, 10),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFFC9935E));
  }

  void _floor(Canvas canvas, double w, double h, double floorY) {
    canvas.drawRect(Rect.fromLTWH(0, floorY, w, h - floorY),
        Paint()..color = const Color(0xFFC9935E));
    final seam = Paint()
      ..color = const Color(0xFFB07E4C)
      ..strokeWidth = 2;
    var row = 0;
    for (var y = floorY + 22; y < h; y += 22, row++) {
      canvas.drawLine(Offset(0, y), Offset(w, y), seam);
      for (var x = (row.isEven ? 0.0 : 60.0); x < w; x += 120) {
        canvas.drawLine(Offset(x, y - 22), Offset(x, y), seam);
      }
    }
    // Light falling from the window onto the floor.
    final glow = _night ? const Color(0x22FFE7A0) : const Color(0x33FFF6D0);
    canvas.drawPath(
        Path()
          ..moveTo(w * .62, floorY)
          ..lineTo(w * .84, floorY)
          ..lineTo(w * .78, h)
          ..lineTo(w * .5, h)
          ..close(),
        Paint()..color = glow);
  }

  @override
  bool shouldRepaint(CampRoomPainter oldDelegate) => oldDelegate.hour != hour;
}
