import 'package:flutter/material.dart';

enum ModeIconKind { catchCat, fishing, rescue, returnHome }

/// Flat mode badges: one colored tile with a single white symbol.
class ModeIcon extends StatelessWidget {
  const ModeIcon({super.key, required this.kind, this.size = 52});
  final ModeIconKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size, child: CustomPaint(painter: _ModeIconPainter(kind)));
}

class _ModeIconPainter extends CustomPainter {
  const _ModeIconPainter(this.kind);
  final ModeIconKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 56, size.height / 56);
    final color = switch (kind) {
      ModeIconKind.catchCat => const Color(0xFFD9657B),
      ModeIconKind.fishing => const Color(0xFF3E9FB0),
      ModeIconKind.rescue => const Color(0xFFF08A3A),
      ModeIconKind.returnHome => const Color(0xFF6B9E4E),
    };
    final tile = RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, 52, 52), const Radius.circular(14));
    canvas.drawRRect(tile, Paint()..color = color);
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
        canvas.drawPath(
            Path()
              ..moveTo(10, 28)
              ..lineTo(28, 12)
              ..lineTo(46, 28)
              ..lineTo(41, 28)
              ..lineTo(41, 44)
              ..lineTo(15, 44)
              ..lineTo(15, 28)
              ..close(),
            white);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(24, 32, 8, 12), const Radius.circular(4)),
            Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModeIconPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
