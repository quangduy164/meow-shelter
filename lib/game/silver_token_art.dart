import 'package:flutter/painting.dart';

/// A silver-blue token stamped with a crescent and a four-point star.
/// Shared by the canvas HUD and Flutter shop UI.
void paintSilverToken(Canvas canvas, Rect bounds) {
  canvas.save();
  canvas.translate(bounds.left, bounds.top);
  canvas.scale(bounds.width / 32, bounds.height / 32);
  final rim = Paint()
    ..color = const Color(0xFF405876)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  canvas.drawCircle(
      const Offset(16, 17.5), 13, Paint()..color = const Color(0x500C1C38));
  canvas.drawCircle(
      const Offset(16, 15.5),
      13,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1FBFF), Color(0xFF98BEDC), Color(0xFF638BB4)],
        ).createShader(const Rect.fromLTWH(3, 2.5, 26, 26)));
  canvas.drawCircle(const Offset(16, 15.5), 13, rim);
  canvas.drawCircle(
      const Offset(16, 15.5), 10, Paint()..color = const Color(0xFF45688E));
  canvas.drawCircle(
      const Offset(16, 15.5),
      10,
      Paint()
        ..color = const Color(0xFFBADCEC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(const Rect.fromLTWH(9, 8, 12, 15)),
      Path()..addOval(const Rect.fromLTWH(13, 6, 11, 14)));
  canvas.drawPath(moon, Paint()..color = const Color(0xFFF3F6CF));
  canvas.drawPath(
      Path()
        ..moveTo(22, 9)
        ..lineTo(23, 12)
        ..lineTo(26, 13)
        ..lineTo(23, 14)
        ..lineTo(22, 17)
        ..lineTo(21, 14)
        ..lineTo(18, 13)
        ..lineTo(21, 12)
        ..close(),
      Paint()..color = const Color(0xFFFFE49E));
  canvas.drawArc(
      const Rect.fromLTWH(5, 4.5, 22, 22),
      -2.8,
      1.3,
      false,
      Paint()
        ..color = const Color(0xDFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.8);
  canvas.restore();
}
