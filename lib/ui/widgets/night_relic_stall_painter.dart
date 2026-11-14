import 'package:flutter/material.dart';

/// Wooden moon-market booth on a 740×370 canvas.
class RelicStallPainter extends CustomPainter {
  const RelicStallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 740, size.height / 370);
    Paint fill(int c) => Paint()..color = Color(c);
    void plank(Rect r, int c, {double radius = 3}) {
      final shape = RRect.fromRectAndRadius(r, Radius.circular(radius));
      canvas.drawRRect(shape.shift(const Offset(0, 3)), fill(0x55000000));
      canvas.drawRRect(shape, fill(c));
      canvas.drawRRect(
          shape,
          Paint()
            ..color = const Color(0xFF4C332C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // Recessed, velvet-lined display.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, 58, 694, 270), const Radius.circular(9)),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF202C49), Color(0xFF4A3650)])
              .createShader(const Rect.fromLTWH(23, 58, 694, 270)));
    // Rear shelf and timber posts.
    plank(const Rect.fromLTWH(32, 298, 676, 13), 0xFFAA7B52);
    for (final x in const [22.0, 698.0]) {
      plank(Rect.fromLTWH(x, 42, 20, 303), 0xFF8E6045);
      canvas.drawLine(
          Offset(x + 6, 78),
          Offset(x + 6, 293),
          Paint()
            ..color = const Color(0xFFB58758)
            ..strokeWidth = 2);
    }
    // Striped awning, with scalloped valance.
    for (var i = 0; i < 12; i++) {
      final x = 10 + i * 60.0;
      final c = i.isEven ? 0xFF666393 : 0xFFE8D6AF;
      final shade = i.isEven ? 0xFF454467 : 0xFFC6AD81;
      canvas.drawPath(
          Path()
            ..moveTo(x + 10, 0)
            ..lineTo(x + 50, 0)
            ..lineTo(x + 60, 57)
            ..lineTo(x, 57)
            ..close(),
          fill(c));
      canvas.drawPath(
          Path()
            ..moveTo(x, 57)
            ..lineTo(x + 60, 57)
            ..lineTo(x + 60, 63)
            ..quadraticBezierTo(x + 30, 85, x, 63)
            ..close(),
          fill(shade));
      canvas.drawLine(
          Offset(x, 57),
          Offset(x + 60, 57),
          Paint()
            ..color = const Color(0x22FFFFFF)
            ..strokeWidth = 2);
    }
    plank(const Rect.fromLTWH(7, 0, 726, 7), 0xFF543D36);
    // Hanging sign and brass fasteners.
    for (final x in const [191.0, 549.0]) {
      canvas.drawLine(
          Offset(x, 3),
          Offset(x, 18),
          Paint()
            ..color = const Color(0xFFD4B47B)
            ..strokeWidth = 3);
    }
    plank(const Rect.fromLTWH(164, 14, 412, 35), 0xFF4D393D, radius: 8);
    for (final x in const [174.0, 566.0]) {
      canvas.drawCircle(Offset(x, 31), 2.5, fill(0xFFD6B16F));
    }
    // Two lanterns tucked under the canopy.
    for (final x in const [49.0, 691.0]) {
      canvas.drawCircle(
          Offset(x, 72),
          25,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x66FFCF6E), Color(0x00FFCF6E)])
                .createShader(
                    Rect.fromCircle(center: Offset(x, 72), radius: 25)));
      canvas.drawLine(
          Offset(x, 49),
          Offset(x, 62),
          Paint()
            ..color = const Color(0xFFD3B37D)
            ..strokeWidth = 2);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, 73), width: 15, height: 20),
              const Radius.circular(5)),
          fill(0xFFFFD47D));
      for (final y in const [61.0, 83.0]) {
        plank(Rect.fromCenter(center: Offset(x, y), width: 20, height: 4),
            0xFF574239);
      }
      canvas.drawLine(
          Offset(x, 64),
          Offset(x, 81),
          Paint()
            ..color = const Color(0x99664F36)
            ..strokeWidth = 1);
    }
    // Thick countertop and front boards.
    plank(const Rect.fromLTWH(18, 309, 704, 58), 0xFF805438, radius: 5);
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(20, 312, 700, 53));
    for (var x = 22.0; x < 720; x += 68) {
      canvas.drawLine(
          Offset(x, 313),
          Offset(x, 365),
          Paint()
            ..color = const Color(0xFF67432F)
            ..strokeWidth = 2);
      canvas.drawLine(
          Offset(x + 7, 320),
          Offset(x + 5, 356),
          Paint()
            ..color = const Color(0x447C9B68)
            ..strokeWidth = 1);
    }
    canvas.restore();
    plank(const Rect.fromLTWH(8, 300, 724, 14), 0xFFC79B62, radius: 4);
    canvas.drawLine(
        const Offset(15, 303),
        const Offset(725, 303),
        Paint()
          ..color = const Color(0xFFE3BD82)
          ..strokeWidth = 2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RelicStallPainter oldDelegate) => false;
}
