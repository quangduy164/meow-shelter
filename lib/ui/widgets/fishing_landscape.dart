import 'package:flutter/material.dart';

/// Normalized scenery keeps the lake centered on different screen sizes.
class FishingLandscape extends CustomPainter {
  const FishingLandscape();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 600);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 600),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8BD5ED), Color(0xFFF5EDBD)])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 600)));
    canvas.drawCircle(
        const Offset(785, 105), 42, Paint()..color = const Color(0xFFFFEAB1));
    final cloud = Paint()..color = const Color(0xBBFFFFFF);
    for (final x in [120.0, 420.0, 850.0]) {
      canvas.drawOval(Rect.fromLTWH(x, 95, 120, 22), cloud);
      canvas.drawOval(Rect.fromLTWH(x + 22, 76, 55, 40), cloud);
    }
    canvas.drawPath(
        Path()
          ..moveTo(0, 310)
          ..lineTo(110, 130)
          ..lineTo(230, 270)
          ..lineTo(390, 85)
          ..lineTo(570, 280)
          ..lineTo(710, 140)
          ..lineTo(880, 275)
          ..lineTo(1000, 155)
          ..lineTo(1000, 420)
          ..lineTo(0, 420)
          ..close(),
        Paint()..color = const Color(0xFF7CAFB2));
    canvas.drawPath(
        Path()
          ..moveTo(340, 146)
          ..lineTo(390, 85)
          ..lineTo(447, 147)
          ..lineTo(411, 132)
          ..lineTo(390, 151)
          ..lineTo(370, 133)
          ..close(),
        Paint()..color = const Color(0xFFEDF6E4));
    canvas.drawPath(
        Path()
          ..moveTo(0, 305)
          ..quadraticBezierTo(160, 185, 330, 295)
          ..quadraticBezierTo(540, 205, 710, 295)
          ..quadraticBezierTo(870, 215, 1000, 290)
          ..lineTo(1000, 600)
          ..lineTo(0, 600)
          ..close(),
        Paint()..color = const Color(0xFF81AD72));
    canvas.drawPath(
        Path()
          ..moveTo(0, 420)
          ..quadraticBezierTo(500, 215, 1000, 420)
          ..lineTo(1000, 600)
          ..lineTo(0, 600)
          ..close(),
        Paint()..color = const Color(0xFFADC77F));
    canvas.drawOval(const Rect.fromLTWH(188, 281, 624, 255),
        Paint()..color = const Color(0xFF72985D));
    canvas.drawOval(const Rect.fromLTWH(200, 280, 600, 240),
        Paint()..color = const Color(0xFFE1D2A2));
    canvas.drawOval(
        const Rect.fromLTWH(214, 293, 572, 212),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF388EAD), Color(0xFF77DAD6)])
              .createShader(const Rect.fromLTWH(214, 293, 572, 212)));
    final ripple = Paint()
      ..color = const Color(0x88D7FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(const Rect.fromLTWH(320, 365, 110, 12), ripple);
    canvas.drawOval(const Rect.fromLTWH(540, 420, 150, 15), ripple);
    for (final x in [65.0, 120.0, 865.0, 930.0]) {
      canvas.drawRect(Rect.fromLTWH(x - 5, 345, 10, 70),
          Paint()..color = const Color(0xFF7B6041));
      canvas.drawPath(
          Path()
            ..moveTo(x, 220)
            ..lineTo(x - 45, 365)
            ..lineTo(x + 45, 365)
            ..close(),
          Paint()..color = const Color(0xFF39765C));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingLandscape oldDelegate) => false;
}
