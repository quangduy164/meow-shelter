import '../design.dart';
import 'package:flutter/material.dart';

enum ModeIconKind { catchCat, fishing, rescue, returnHome, camp, herd }

/// Flat mode badges: one colored tile with a single white symbol.
class ModeIcon extends StatelessWidget {
  const ModeIcon(
      {super.key, required this.kind, this.size = 52, this.onColor = false});
  final ModeIconKind kind;
  final double size;

  /// On a coloured tile: draw a translucent white badge instead of a colour one.
  final bool onColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ModeIconPainter(kind, onColor)));
}

class _ModeIconPainter extends CustomPainter {
  const _ModeIconPainter(this.kind, this.onColor);
  final ModeIconKind kind;
  final bool onColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 56, size.height / 56);
    final color = switch (kind) {
      ModeIconKind.catchCat => const Color(0xFFD9657B),
      ModeIconKind.fishing => DS.modeFishing,
      ModeIconKind.rescue => DS.modeRescue,
      ModeIconKind.returnHome => DS.modeReturnHome,
      ModeIconKind.camp => DS.modeCamp,
      ModeIconKind.herd => DS.modeHerd,
    };
    final tile = RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, 52, 52), const Radius.circular(14));
    canvas.drawRRect(
        tile, Paint()..color = onColor ? const Color(0x33FFFFFF) : color);
    final white = Paint()..color = Colors.white;
    switch (kind) {
      case ModeIconKind.catchCat:
        canvas.drawPath(
            Path()
              ..moveTo(13, 26)
              ..lineTo(15, 11)
              ..lineTo(23, 19)
              ..quadraticBezierTo(28, 17, 33, 19)
              ..lineTo(41, 11)
              ..lineTo(43, 26)
              ..quadraticBezierTo(45, 44, 28, 45)
              ..quadraticBezierTo(11, 44, 13, 26)
              ..close(),
            white);
        final face = Paint()..color = color;
        canvas.drawCircle(const Offset(22, 30), 2.4, face);
        canvas.drawCircle(const Offset(34, 30), 2.4, face);
        canvas.drawPath(
            Path()
              ..moveTo(25.5, 35)
              ..lineTo(30.5, 35)
              ..lineTo(28, 38)
              ..close(),
            face);
      case ModeIconKind.fishing:
        canvas.drawPath(
            Path()
              ..moveTo(10, 28)
              ..quadraticBezierTo(22, 14, 36, 28)
              ..quadraticBezierTo(22, 42, 10, 28)
              ..close(),
            white);
        canvas.drawPath(
            Path()
              ..moveTo(34, 28)
              ..lineTo(46, 19)
              ..lineTo(46, 37)
              ..close(),
            white);
        canvas.drawCircle(const Offset(18, 26), 2.2, Paint()..color = color);
      case ModeIconKind.rescue:
        canvas.drawOval(
            Rect.fromCenter(
                center: const Offset(28, 35), width: 20, height: 16),
            white);
        for (final toe in const [
          Offset(16, 23),
          Offset(24, 17),
          Offset(32, 17),
          Offset(40, 23),
        ]) {
          canvas.drawOval(
              Rect.fromCenter(center: toe, width: 8, height: 10), white);
        }
      case ModeIconKind.returnHome:
        final road = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
            Path()
              ..moveTo(12, 44)
              ..quadraticBezierTo(30, 40, 22, 30)
              ..quadraticBezierTo(14, 20, 34, 16),
            road);
        canvas.drawLine(
            const Offset(36, 30),
            const Offset(36, 10),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 3);
        canvas.drawPath(
            Path()
              ..moveTo(37, 10)
              ..lineTo(47, 14)
              ..lineTo(37, 18)
              ..close(),
            white);
      case ModeIconKind.herd:
        for (final c in [
          const Offset(15, 39),
          const Offset(28, 28),
          const Offset(41, 17)
        ]) {
          canvas.drawCircle(c, 7, white);
          canvas.drawPath(
              Path()
                ..moveTo(c.dx - 6, c.dy - 3)
                ..lineTo(c.dx - 6, c.dy - 11)
                ..lineTo(c.dx, c.dy - 6)
                ..lineTo(c.dx + 6, c.dy - 11)
                ..lineTo(c.dx + 6, c.dy - 3)
                ..close(),
              white);
        }
      case ModeIconKind.camp:
        canvas.drawPath(
            Path()
              ..moveTo(9, 27)
              ..lineTo(28, 11)
              ..lineTo(47, 27)
              ..close(),
            white);
        canvas.drawRect(const Rect.fromLTWH(14, 26, 28, 19), white);
        final heart = Paint()
          ..color = onColor ? const Color(0xFFC85A7C) : color;
        canvas.drawPath(
            Path()
              ..moveTo(28, 41)
              ..cubicTo(18, 34, 21, 26, 28, 31)
              ..cubicTo(35, 26, 38, 34, 28, 41)
              ..close(),
            heart);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModeIconPainter oldDelegate) =>
      kind != oldDelegate.kind || onColor != oldDelegate.onColor;
}
