import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../fishing/fishing_lighting.dart';

class FishingSkyPainter extends CustomPainter {
  const FishingSkyPainter(
      {required this.sceneHeight, required this.lighting, required this.clock});
  final double sceneHeight, clock;
  final FishingLighting lighting;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.width, sceneHeight));
    canvas.scale(size.width / 1000, sceneHeight / 600);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 600),
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lighting.skyTop, lighting.skyBottom],
                  stops: const [0, .6])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 600)));
    final random = math.Random(207);
    for (var i = 0; i < 65; i++) {
      final center = Offset(
          25 + random.nextDouble() * 950, 18 + random.nextDouble() * 245);
      final radius = .9 + random.nextDouble() * 1.3;
      final opacity = lighting.night *
          (.35 + .35 * (1 + math.sin(clock * .8 + i * 2.4)) / 2);
      canvas.drawCircle(center, radius,
          Paint()..color = Color.fromRGBO(240, 246, 224, opacity));
      if (i % 11 == 0) {
        final star = Paint()
          ..color = Color.fromRGBO(240, 246, 224, opacity)
          ..strokeWidth = 1;
        canvas.drawLine(
            center - const Offset(4, 0), center + const Offset(4, 0), star);
        canvas.drawLine(
            center - const Offset(0, 4), center + const Offset(0, 4), star);
      }
    }
    final body = lighting.celestialPosition;
    final center = Offset(body.dx * 1000, body.dy * 600);
    if (lighting.moonVisible) {
      final moon = Paint()
        ..color = Color.fromRGBO(239, 242, 215, lighting.night);
      canvas.drawCircle(center, 29, moon);
      for (final crater in [
        const Offset(-10, -8),
        const Offset(9, 9),
        const Offset(12, -12)
      ]) {
        canvas.drawCircle(
            center + crater,
            crater.dx < 0 ? 6 : 4,
            Paint()
              ..color = Color.fromRGBO(164, 191, 185, lighting.night * .45));
      }
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: 32),
          -2.4,
          1.1,
          false,
          Paint()
            ..color = Color.fromRGBO(231, 241, 217, lighting.night * .35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    } else {
      canvas.drawCircle(
          center,
          34,
          Paint()
            ..color = Color.lerp(const Color(0xFFFFF1BD),
                const Color(0xFFFFCB8F), lighting.warmth)!);
      canvas.drawCircle(
          center,
          39,
          Paint()
            ..color = const Color(0x33FFF3CD)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    for (var i = 0; i < 5; i++) {
      final x = (i * 265 + clock * (3.5 + i * .7)) % 1320 - 160;
      final y = 65 + (i % 3) * 43.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(i.isEven ? 1 : .74);
      final cloud = Path()
        ..moveTo(0, 23)
        ..cubicTo(-9, 12, 8, 3, 23, 8)
        ..cubicTo(29, -16, 64, -19, 75, 3)
        ..cubicTo(91, -8, 110, 2, 113, 14)
        ..cubicTo(144, 10, 159, 31, 129, 33)
        ..cubicTo(91, 36, 27, 34, 0, 23)
        ..close();
      canvas.drawPath(
          cloud,
          Paint()
            ..color = Color.lerp(const Color(0xBBEAF6ED),
                const Color(0x557C939C), lighting.night)!);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingSkyPainter oldDelegate) =>
      sceneHeight != oldDelegate.sceneHeight ||
      clock != oldDelegate.clock ||
      lighting.hour != oldDelegate.lighting.hour;
}
