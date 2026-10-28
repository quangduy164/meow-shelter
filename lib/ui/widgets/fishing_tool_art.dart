import 'package:flutter/material.dart';

enum FishingTool { back, basket, float, hook, reel, save }

class FishingToolArt extends CustomPainter {
  const FishingToolArt(
      {required this.tool,
      this.rotation = 0,
      this.active = false,
      this.alert = false});
  final FishingTool tool;
  final double rotation;
  final bool active, alert;
  static const ink = Color(0xFF493F30);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawOval(const Rect.fromLTWH(19, 87, 65, 7),
        Paint()..color = const Color(0x28443626));
    switch (tool) {
      case FishingTool.back:
        final arrow = Path()
          ..moveTo(9, 48)
          ..lineTo(39, 21)
          ..lineTo(39, 35)
          ..lineTo(88, 32)
          ..lineTo(91, 65)
          ..lineTo(40, 63)
          ..lineTo(40, 78)
          ..close();
        _shape(
            canvas, arrow.shift(const Offset(0, 4)), const Color(0xFF796048));
        _shape(canvas, arrow, const Color(0xFFD8B174));
        canvas.save();
        canvas.clipPath(arrow);
        for (var i = 0; i < 5; i++) {
          _line(
              canvas,
              Path()
                ..moveTo(14, 34 + i * 8)
                ..quadraticBezierTo(51, 28 + i * 8, 92, 35 + i * 8),
              const Color(0x556D4E32),
              1);
        }
        canvas.restore();
        _line(
            canvas,
            Path()
              ..moveTo(19, 47)
              ..lineTo(35, 32),
            const Color(0xFFFFE6AE),
            2);
        for (final x in [48.0, 81.0]) {
          canvas.drawCircle(
              Offset(x, 43), 2, Paint()..color = const Color(0xFF655949));
        }
      case FishingTool.basket:
        _line(
            canvas,
            Path()
              ..moveTo(26, 42)
              ..cubicTo(23, 5, 78, 5, 76, 42),
            ink,
            9);
        _line(
            canvas,
            Path()
              ..moveTo(26, 41)
              ..cubicTo(24, 10, 76, 10, 76, 41),
            const Color(0xFFC5A77D),
            4);
        _fish(canvas, const Offset(48, 34), -.4);
        final body = Path()
          ..moveTo(17, 41)
          ..lineTo(84, 41)
          ..lineTo(77, 85)
          ..quadraticBezierTo(49, 93, 24, 84)
          ..close();
        _shape(canvas, body, const Color(0xFFC49B60));
        canvas.save();
        canvas.clipPath(body);
        for (var i = 0; i < 9; i++) {
          final y = 43 + i * 5.0;
          _line(
              canvas,
              Path()
                ..moveTo(15, y)
                ..quadraticBezierTo(50, y + 7, 86, y),
              i.isEven ? const Color(0xFFE3C086) : const Color(0xFF8E6B43),
              2.4);
        }
        for (var i = 0; i < 8; i++) {
          _line(
              canvas,
              Path()
                ..moveTo(20 + i * 9, 40)
                ..lineTo(28 + i * 7, 92),
              const Color(0xAA9A774A),
              1.6);
        }
        canvas.restore();
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(14, 37, 73, 10), const Radius.circular(4)),
            Paint()..color = ink);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(16, 37, 69, 5), const Radius.circular(3)),
            Paint()..color = const Color(0xFFE3C086));
        _shape(
            canvas,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  const Rect.fromLTWH(44, 49, 14, 18),
                  const Radius.circular(3))),
            const Color(0xFF6D7863));
        canvas.drawCircle(
            const Offset(51, 56), 2, Paint()..color = const Color(0xFFE5C57F));
      case FishingTool.float:
        canvas.save();
        canvas.translate(48, 45);
        canvas.rotate(.3);
        _line(
            canvas,
            Path()
              ..moveTo(0, -34)
              ..lineTo(0, 38)
              ..quadraticBezierTo(1, 49, 17, 43),
            ink,
            2);
        _shape(
            canvas,
            Path()
              ..moveTo(0, -26)
              ..cubicTo(-24, -10, -19, 17, 0, 28)
              ..cubicTo(19, 17, 24, -10, 0, -26)
              ..close(),
            const Color(0xFFFFF3D7));
        canvas.save();
        canvas.clipPath(Path()
          ..moveTo(0, -26)
          ..cubicTo(-24, -10, -19, 17, 0, 28)
          ..cubicTo(19, 17, 24, -10, 0, -26)
          ..close());
        canvas.drawRect(const Rect.fromLTWH(-24, -28, 48, 27),
            Paint()..color = const Color(0xFFD95E48));
        _line(
            canvas,
            Path()
              ..moveTo(-9, -13)
              ..quadraticBezierTo(-14, -3, -10, 7),
            const Color(0x99FFFFFF),
            3);
        canvas.restore();
        canvas.restore();
        _line(
            canvas,
            Path()
              ..moveTo(73, 59)
              ..lineTo(73, 80)
              ..cubicTo(73, 92, 91, 89, 87, 75),
            const Color(0xFF607A79),
            3);
        _line(
            canvas,
            Path()
              ..moveTo(87, 75)
              ..lineTo(82, 81),
            const Color(0xFF607A79),
            3);
      case FishingTool.hook:
        _line(
            canvas,
            Path()
              ..moveTo(22, 84)
              ..quadraticBezierTo(37, 41, 67, 17),
            ink,
            8);
        _line(
            canvas,
            Path()
              ..moveTo(22, 82)
              ..quadraticBezierTo(38, 40, 67, 17),
            const Color(0xFFC9A668),
            4);
        _line(
            canvas,
            Path()
              ..moveTo(20, 87)
              ..lineTo(31, 63),
            const Color(0xFF72523A),
            11);
        for (var i = 0; i < 4; i++) {
          _line(
              canvas,
              Path()
                ..moveTo(20 + i * 2, 78 - i * 4)
                ..lineTo(28 + i * 2, 81 - i * 4),
              const Color(0xFFD1AF7A),
              1);
        }
        _line(
            canvas,
            Path()
              ..moveTo(67, 18)
              ..quadraticBezierTo(90, 40, 78, 65)
              ..cubicTo(68, 90, 49, 74, 59, 62),
            const Color(0xFF577779),
            2.5);
        _shape(
            canvas,
            Path()
              ..moveTo(59, 62)
              ..lineTo(58, 72)
              ..lineTo(64, 68)
              ..close(),
            const Color(0xFF577779));
        if (alert) {
          for (var i = 0; i < 3; i++) {
            final x = 74 + i * 7.0;
            _line(
                canvas,
                Path()
                  ..moveTo(x, 12)
                  ..lineTo(x + 4, 4 + i * 3),
                const Color(0xFFD35B3E),
                3);
          }
        }
      case FishingTool.reel:
        _shape(
            canvas,
            Path()
              ..moveTo(38, 64)
              ..lineTo(33, 84)
              ..lineTo(62, 86)
              ..lineTo(59, 78)
              ..lineTo(49, 76)
              ..lineTo(54, 63)
              ..close(),
            const Color(0xFF577C77));
        final body = Path()..addOval(const Rect.fromLTWH(17, 20, 62, 57));
        _shape(canvas, body, const Color(0xFF577C77));
        _shape(canvas, Path()..addOval(const Rect.fromLTWH(22, 21, 49, 49)),
            const Color(0xFFE5CC93));
        _shape(canvas, Path()..addOval(const Rect.fromLTWH(27, 26, 39, 39)),
            const Color(0xFF8C9F90));
        for (var i = 0; i < 6; i++) {
          canvas.drawOval(
              Rect.fromLTWH(31 + i * 2, 29 + i * 2, 30 - i * 4, 30 - i * 4),
              Paint()
                ..color = const Color(0xFFDBD8B6)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.3);
        }
        canvas.save();
        canvas.translate(48, 46);
        canvas.rotate(rotation);
        _line(
            canvas,
            Path()
              ..moveTo(0, 0)
              ..lineTo(20, 18)
              ..lineTo(30, 18),
            ink,
            7);
        _line(
            canvas,
            Path()
              ..moveTo(0, 0)
              ..lineTo(20, 18)
              ..lineTo(30, 18),
            const Color(0xFFDCBA7F),
            4);
        _shape(
            canvas,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  const Rect.fromLTWH(24, 9, 15, 22),
                  const Radius.circular(6))),
            active ? const Color(0xFFD7954C) : const Color(0xFF886147));
        canvas.restore();
        canvas.drawCircle(const Offset(48, 46), 6, Paint()..color = ink);
        canvas.drawCircle(
            const Offset(47, 45), 3, Paint()..color = const Color(0xFFF7DF9E));
      case FishingTool.save:
        _shape(
            canvas,
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  const Rect.fromLTWH(24, 19, 52, 63),
                  const Radius.circular(5))),
            const Color(0xFF577C77));
        _shape(canvas, Path()..addRect(const Rect.fromLTWH(34, 19, 31, 23)),
            const Color(0xFFFFE7BA));
        _line(
            canvas,
            Path()
              ..moveTo(37, 61)
              ..lineTo(47, 70)
              ..lineTo(65, 50),
            const Color(0xFFFFE7BA),
            5);
    }
    canvas.restore();
  }

  void _shape(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
  }

  void _line(Canvas canvas, Path path, Color color, double width) =>
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round);

  void _fish(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    _shape(canvas, Path()..addOval(const Rect.fromLTWH(-16, -9, 31, 18)),
        const Color(0xFF8EBCAD));
    _shape(
        canvas,
        Path()
          ..moveTo(12, 0)
          ..lineTo(27, -11)
          ..lineTo(26, 10)
          ..close(),
        const Color(0xFF659D95));
    canvas.drawCircle(const Offset(-8, -2), 2, Paint()..color = ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingToolArt oldDelegate) =>
      tool != oldDelegate.tool ||
      rotation != oldDelegate.rotation ||
      active != oldDelegate.active ||
      alert != oldDelegate.alert;
}
