import 'package:flutter/material.dart';
import '../../collection/fish_species.dart';

class FishingJunkArt extends CustomPainter {
  const FishingJunkArt(this.item, {this.locked = false});
  final FishSpecies item;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = (size.width / 100).clamp(0.0, size.height / 64);
    canvas.scale(scale);
    final outline = Paint()
      ..color = const Color(0xFF3E5B55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Color color(Color value) => locked ? const Color(0xFFABB9B1) : value;
    canvas.drawOval(const Rect.fromLTWH(-31, 24, 64, 5),
        Paint()..color = const Color(0x18426058));
    switch (item) {
      case FishSpecies.flipFlop:
        canvas.rotate(-.4);
        final sole = Path()
          ..moveTo(-13, 24)
          ..cubicTo(-26, 10, -22, -25, -5, -27)
          ..cubicTo(18, -31, 25, -8, 15, 12)
          ..quadraticBezierTo(8, 32, -13, 24)
          ..close();
        canvas.drawPath(sole.shift(const Offset(0, 3)),
            Paint()..color = color(const Color(0xFF41777C)));
        canvas.drawPath(sole, Paint()..color = color(const Color(0xFF7AC9C4)));
        canvas.drawPath(sole, outline);
        for (var i = 0; i < 5; i++) {
          canvas.drawLine(
              Offset(-11, 3 + i * 4.0),
              Offset(8, 3 + i * 4.0),
              Paint()
                ..color = const Color(0x5541777C)
                ..strokeWidth = 1);
        }
        final strap = Path()
          ..moveTo(-19, -3)
          ..quadraticBezierTo(-7, -14, -3, -9)
          ..quadraticBezierTo(5, -14, 18, -5)
          ..moveTo(-3, -9)
          ..lineTo(-4, -20);
        canvas.drawPath(strap, outline..strokeWidth = 7);
        canvas.drawPath(
            strap,
            Paint()
              ..color = color(const Color(0xFFF2BB70))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round);
        canvas.drawCircle(
            const Offset(-4, -20), 3, Paint()..color = const Color(0xFFE58069));
      case FishSpecies.oldBoot:
        final boot = Path()
          ..moveTo(-14, -26)
          ..lineTo(14, -26)
          ..lineTo(10, 2)
          ..cubicTo(12, 5, 34, 4, 35, 16)
          ..lineTo(34, 24)
          ..lineTo(-24, 24)
          ..lineTo(-24, 11)
          ..quadraticBezierTo(-13, -2, -14, -26)
          ..close();
        canvas.drawPath(boot, Paint()..color = color(const Color(0xFF9CAC66)));
        canvas.drawPath(boot, outline);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(-25, 20, 61, 7), const Radius.circular(2)),
            Paint()..color = color(const Color(0xFF58674B)));
        canvas.drawOval(const Rect.fromLTWH(-16, -30, 32, 9),
            Paint()..color = const Color(0xFF40594D));
        canvas.drawOval(const Rect.fromLTWH(-16, -30, 32, 9), outline);
        canvas.drawRRect(
            RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -12, 15, 12),
                const Radius.circular(2)),
            Paint()..color = color(const Color(0xFFE3C388)));
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(Offset(-10 + i * 5.0, -14), Offset(-9 + i * 5.0, -9),
              outline..strokeWidth = 1);
        }
        canvas.drawOval(const Rect.fromLTWH(15, 11, 13, 5),
            Paint()..color = const Color(0x447C694B));
      case FishSpecies.tinCan:
        canvas.rotate(.3);
        final can = Path()
          ..moveTo(-19, -20)
          ..lineTo(18, -20)
          ..lineTo(20, -3)
          ..lineTo(13, 4)
          ..lineTo(20, 12)
          ..lineTo(18, 24)
          ..quadraticBezierTo(0, 29, -19, 23)
          ..close();
        canvas.drawPath(can, Paint()..color = color(const Color(0xFFB4C9C4)));
        canvas.drawPath(can, outline);
        canvas.drawRect(const Rect.fromLTWH(-18, -7, 35, 18),
            Paint()..color = color(const Color(0xFFE68A78)));
        canvas.drawOval(const Rect.fromLTWH(-20, -25, 39, 10),
            Paint()..color = const Color(0xFF6C8C83));
        canvas.drawOval(const Rect.fromLTWH(-20, -25, 39, 10), outline);
        canvas.drawOval(
            const Rect.fromLTWH(-10, -26, 17, 6), outline..strokeWidth = 2.5);
        canvas.drawCircle(
            const Offset(-6, 0), 2, Paint()..color = const Color(0xFF3E5B55));
        canvas.drawCircle(
            const Offset(5, 0), 2, Paint()..color = const Color(0xFF3E5B55));
        canvas.drawArc(const Rect.fromLTWH(-5, 3, 10, 7), 0, 3.14, false,
            outline..strokeWidth = 1.5);
        canvas.drawLine(const Offset(-17, 17), const Offset(14, 17),
            outline..strokeWidth = 1);
      default:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingJunkArt oldDelegate) =>
      item != oldDelegate.item || locked != oldDelegate.locked;
}
